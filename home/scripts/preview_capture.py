"""Capture one Hyprland window to an in-memory, opaque PNG thumbnail."""
import base64
import functools
import io
import json
import mmap
import os
import select
import sys
import time

from PIL import Image


def decode_frame(data, width, height, stride, format_, inverted=False):
    # wl_shm format zero/one are ARGB/XRGB; other values are DRM FourCCs.
    # Ignore alpha deliberately: window surfaces can contain zero alpha even
    # when the compositor supplied valid RGB pixels for the preview.
    formats = {0: "BGRX", 1: "BGRX", 0x34324241: "RGBX", 0x34324258: "RGBX"}
    if format_ not in formats:
        raise ValueError("unsupported-shm-format: " + hex(format_))
    if not (0 < width <= 8192 and 0 < height <= 8192 and width * 4 <= stride <= width * 4 + 4096
            and stride * height <= 128 * 1024 * 1024):
        raise ValueError("invalid-buffer-size")
    if len(data) != stride * height:
        raise ValueError("incomplete-frame")
    image = Image.frombytes("RGB", (width, height), data, "raw", formats[format_], stride, -1 if inverted else 1)
    image.thumbnail((800, 600), Image.Resampling.LANCZOS)
    result = io.BytesIO()
    image.save(result, format="PNG")
    return {"ok": True, "width": width, "height": height,
            "image": "data:image/png;base64," + base64.b64encode(result.getvalue()).decode("ascii")}


class Capture:
    def __init__(self, address):
        self.address = int(address, 16)
        if not self.address or self.address >= 2 ** 64:
            raise ValueError("invalid-window-address")
        self.error = None
        self.result = None
        self.shm = self.mapping = self.export = self.toplevel_manager = None
        self.frame = self.pool = self.buffer = None
        self.memory = None
        self.fd = None
        self.flags = 0
        self.spec = None
        self.handles = []
        self.mappings = []

    def listen(self, proxy, event, handler):
        # CFFI callbacks otherwise print and swallow exceptions.
        @functools.wraps(handler)
        def callback(*args):
            try:
                return handler(*args)
            except Exception as error:
                self.error = self.error or str(error)
        proxy.dispatcher[event] = callback

    def global_(self, registry, name, interface, version):
        from pywayland.protocol.wayland import WlShm
        from preview_protocols.hyprland_toplevel_export_v1 import HyprlandToplevelExportManagerV1
        from preview_protocols.hyprland_toplevel_mapping_v1 import HyprlandToplevelMappingManagerV1
        from preview_protocols.wlr_foreign_toplevel_management_unstable_v1 import ZwlrForeignToplevelManagerV1
        bindings = {"wl_shm": ("shm", WlShm, 1),
                    "hyprland_toplevel_export_manager_v1": ("export", HyprlandToplevelExportManagerV1, 2),
                    "hyprland_toplevel_mapping_manager_v1": ("mapping", HyprlandToplevelMappingManagerV1, 1),
                    "zwlr_foreign_toplevel_manager_v1": ("toplevel_manager", ZwlrForeignToplevelManagerV1, 3)}
        if interface in bindings:
            attr, cls, maximum = bindings[interface]
            if interface == "hyprland_toplevel_export_manager_v1" and version < 2:
                raise ValueError("toplevel-export-v2-required")
            proxy = registry.bind(name, cls, min(version, maximum))
            setattr(self, attr, proxy)
            if attr == "toplevel_manager":
                self.listen(proxy, "toplevel", self.toplevel)

    def globals_done(self, *_):
        if any(proxy is None for proxy in (self.shm, self.mapping, self.export, self.toplevel_manager)):
            raise ValueError("required-capture-protocol-unavailable")

    def toplevel(self, _, handle):
        self.handles.append(handle)
        self.listen(handle, "done", self.toplevel_done)

    def toplevel_done(self, handle):
        if getattr(handle, "preview_mapped", False):
            return
        handle.preview_mapped = True
        mapping = self.mapping.get_window_for_toplevel_wlr(handle)
        self.mappings.append(mapping)
        self.listen(mapping, "window_address", lambda _, hi, lo: self.mapped(handle, hi, lo))

    def mapped(self, handle, hi, lo):
        # Compare all 64 bits. Do not select a window by title or app class.
        if ((hi << 32) | lo) != self.address or self.frame is not None:
            return
        self.frame = self.export.capture_toplevel_with_wlr_toplevel_handle(0, handle)
        self.listen(self.frame, "buffer", self.offered_buffer)
        self.listen(self.frame, "buffer_done", self.buffer_done)
        self.listen(self.frame, "flags", lambda _, flags: setattr(self, "flags", flags))
        self.listen(self.frame, "ready", self.ready)
        self.listen(self.frame, "failed", lambda _: setattr(self, "error", "compositor-capture-failed"))

    def offered_buffer(self, _, format_, width, height, stride):
        # Check bounds and supported formats before allocating compositor sizes.
        if format_ not in (0, 1, 0x34324241, 0x34324258):
            raise ValueError("unsupported-shm-format: " + hex(format_))
        if not (0 < width <= 8192 and 0 < height <= 8192 and width * 4 <= stride <= width * 4 + 4096
                and stride * height <= 128 * 1024 * 1024):
            raise ValueError("invalid-buffer-size")
        self.spec = (width, height, stride, format_)

    def buffer_done(self, _):
        if self.spec is None:
            raise ValueError("no-shm-buffer-offered")
        width, height, stride, format_ = self.spec
        self.fd = os.memfd_create("nocturne-preview", os.MFD_CLOEXEC)
        os.ftruncate(self.fd, stride * height)
        self.memory = mmap.mmap(self.fd, stride * height)
        self.pool = self.shm.create_pool(self.fd, stride * height)
        self.buffer = self.pool.create_buffer(0, width, height, stride, format_)
        self.frame.copy(self.buffer, 1)

    def ready(self, *_):
        self.result = decode_frame(self.memory[:], *self.spec, bool(self.flags & 1))

    def run(self, timeout=3.0):
        from pywayland.client import Display
        display = Display()
        try:
            display.connect()
            registry = display.get_registry()
            self.listen(registry, "global", self.global_)
            sync = display.sync()
            self.listen(sync, "done", self.globals_done)
            deadline = time.monotonic() + timeout
            while self.result is None and self.error is None:
                display.dispatch(block=False)
                if self.result is not None or self.error is not None:
                    break
                display.flush()
                remaining = deadline - time.monotonic()
                if remaining <= 0 or not select.select([display.get_fd()], [], [], max(0, remaining))[0]:
                    raise TimeoutError("capture-timeout")
                display.dispatch(block=True)
            if self.error:
                raise ValueError(self.error)
            return self.result
        finally:
            display.disconnect()
            if self.memory is not None:
                self.memory.close()
            if self.fd is not None:
                os.close(self.fd)


def main():
    try:
        if len(sys.argv) != 2:
            raise ValueError("expected-window-address")
        print(json.dumps(Capture(sys.argv[1]).run(), separators=(",", ":")))
        return 0
    except Exception as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
