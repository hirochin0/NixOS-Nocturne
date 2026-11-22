"""Exercise the real client against a small Wayland wire-protocol fixture."""
import array
import base64
import importlib.util
import io
import json
import mmap
import os
from pathlib import Path
import socket
import struct
import subprocess
import sys
import threading
import unittest

from PIL import Image

SCRIPT = Path(sys.argv.pop(1)).resolve()
spec = importlib.util.spec_from_file_location("capture", SCRIPT)
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


def uints(*values):
    return struct.pack("=" + "I" * len(values), *values)


def string(value):
    data = value.encode() + b"\0"
    return uints(len(data)) + data + b"\0" * (-len(data) % 4)


class Compositor:
    addresses = (0x1111000012345678, 0x2222000012345678)

    def __init__(self, connection, fail=False):
        self.connection = connection
        self.objects = {1: "wl_display"}
        self.pool_fd = None
        self.memory = None
        self.selected = None
        self.error = None
        self.fail = fail

    def send(self, obj, opcode, data=b""):
        self.connection.sendall(uints(obj, ((8 + len(data)) << 16) | opcode) + data)

    def request(self, obj, op, data, fds):
        kind = self.objects[obj]
        words = struct.unpack("=" + "I" * (len(data) // 4), data)
        if kind == "wl_display" and op == 1:
            registry = words[0]
            self.objects[registry] = "wl_registry"
            for name, iface, version in [(10, "wl_shm", 1), (20, "zwlr_foreign_toplevel_manager_v1", 3),
                                         (30, "hyprland_toplevel_mapping_manager_v1", 1),
                                         (40, "hyprland_toplevel_export_manager_v1", 2)]:
                self.send(registry, 0, uints(name) + string(iface) + uints(version))
        elif kind == "wl_display" and op == 0:
            self.send(words[0], 0, uints(1))
        elif kind == "wl_registry":
            length = words[1]
            iface = data[8:8 + length - 1].decode()
            new_id = words[-1]
            self.objects[new_id] = iface
            if iface == "zwlr_foreign_toplevel_manager_v1":
                for index in range(2):
                    handle = 0xff000000 + index
                    self.objects[handle] = "zwlr_foreign_toplevel_handle_v1"
                    self.send(new_id, 0, uints(handle))
                    self.send(handle, 5)  # done
        elif kind == "hyprland_toplevel_mapping_manager_v1" and op == 1:
            mapping, handle = words
            self.objects[mapping] = "mapping"
            address = self.addresses[handle - 0xff000000]
            self.send(mapping, 0, uints(address >> 32, address & 0xffffffff))
        elif kind == "hyprland_toplevel_export_manager_v1" and op == 2:
            frame, _, handle = words
            self.selected = self.addresses[handle - 0xff000000]
            self.objects[frame] = "frame"
            if self.fail:
                self.send(frame, 4)  # failed
            else:
                # ARGB with zero alpha and padded stride: the resulting PNG
                # must nevertheless show the non-black RGB pixels.
                self.send(frame, 0, uints(0, 2, 2, 12))
                self.send(frame, 6)  # buffer_done
        elif kind == "wl_shm" and op == 0:
            pool, size = words
            self.objects[pool] = "pool"
            self.pool_fd = fds.pop(0)
            self.memory = mmap.mmap(self.pool_fd, size)
        elif kind == "pool" and op == 0:
            self.objects[words[0]] = "buffer"
        elif kind == "frame" and op == 0:
            self.memory[:] = bytes([0, 0, 255, 0, 0, 255, 0, 0, 0, 0, 0, 0,
                                    255, 0, 0, 0, 255, 255, 255, 0, 0, 0, 0, 0])
            self.send(obj, 2, uints(1))  # y-inverted
            self.send(obj, 3, uints(0, 1, 0))  # ready

    def run(self):
        pending = b""
        fds = []
        try:
            while True:
                data, ancillary, _, _ = self.connection.recvmsg(65536, socket.CMSG_SPACE(16))
                if not data:
                    break
                pending += data
                for level, kind, content in ancillary:
                    if level == socket.SOL_SOCKET and kind == socket.SCM_RIGHTS:
                        descriptors = array.array("i")
                        descriptors.frombytes(content[:len(content) - len(content) % descriptors.itemsize])
                        fds.extend(descriptors)
                while len(pending) >= 8:
                    obj, header = struct.unpack("=II", pending[:8])
                    size = header >> 16
                    if len(pending) < size:
                        break
                    self.request(obj, header & 0xffff, pending[8:size], fds)
                    pending = pending[size:]
        except Exception as error:
            self.error = error
        finally:
            if self.memory is not None:
                self.memory.close()
            if self.pool_fd is not None:
                os.close(self.pool_fd)
            for fd in fds:
                os.close(fd)
            self.connection.close()


class CaptureTest(unittest.TestCase):
    def run_capture(self, fail=False):
        server, client = socket.socketpair()
        fixture = Compositor(server, fail)
        thread = threading.Thread(target=fixture.run, daemon=True)
        thread.start()
        env = dict(os.environ, WAYLAND_SOCKET=str(client.fileno()))
        process = subprocess.run([sys.executable, str(SCRIPT), hex(fixture.addresses[1])],
                                 env=env, pass_fds=(client.fileno(),), capture_output=True, timeout=6)
        client.close()
        thread.join(2)
        self.assertIsNone(fixture.error, process.stderr.decode() + process.stdout.decode())
        self.assertEqual(fixture.selected, fixture.addresses[1], process.stderr.decode() + process.stdout.decode())
        return process

    def test_actual_protocol_to_png(self):
        process = self.run_capture()
        self.assertEqual(process.returncode, 0, process.stderr.decode() + process.stdout.decode())
        result = json.loads(process.stdout)
        self.assertEqual((result["width"], result["height"]), (2, 2))
        image = Image.open(io.BytesIO(base64.b64decode(result["image"].split(",")[1])))
        self.assertEqual(image.mode, "RGB")
        self.assertEqual(image.getpixel((0, 0)), (0, 0, 255))
        self.assertEqual(image.getpixel((0, 1)), (255, 0, 0))

    def test_compositor_failure(self):
        process = self.run_capture(fail=True)
        self.assertEqual(process.returncode, 1)
        self.assertEqual(json.loads(process.stdout)["error"], "compositor-capture-failed")

    def test_invalid_and_oversized_buffers(self):
        for args in [(1, 1, 4, 99), (100000, 1, 400000, 0), (2, 2, 4, 0)]:
            with self.assertRaises(ValueError):
                capture.decode_frame(b"", *args)

    def test_downsize(self):
        result = capture.decode_frame(bytes([0, 0, 255, 0]) * 1920 * 1080, 1920, 1080, 1920 * 4, 0)
        image = Image.open(io.BytesIO(base64.b64decode(result["image"].split(",")[1])))
        self.assertEqual(image.size, (800, 450))


if __name__ == "__main__":
    unittest.main()
