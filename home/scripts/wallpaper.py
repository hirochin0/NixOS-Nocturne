"""swww wallpaper selection and per-user state; no shell interpolation."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from PIL import Image, ImageDraw, ImageOps, UnidentifiedImageError


def run(command, **kwargs):
    return subprocess.run(command, check=False, **kwargs)


def ready(swww):
    for _ in range(40):
        try:
            if run([swww, "query"], stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL, timeout=0.3).returncode == 0:
                return
        except subprocess.TimeoutExpired:
            pass
        time.sleep(0.1)
    raise RuntimeError("swww daemon is not ready; check nocturne-wallpaper.service")


def state_file():
    base = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    return base / "nocturne/wallpaper.json"


def remember(image):
    state = state_file()
    state.parent.mkdir(parents=True, exist_ok=True)
    # Atomic replacement; a failed swww request never changes the selection.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=state.parent, delete=False) as out:
            temporary = Path(out.name)
            json.dump({"image": str(image)}, out)
        temporary.replace(state)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def saved_or_default(default):
    try:
        image = Path(json.loads(state_file().read_text())["image"])
        if image.is_absolute() and image.is_file():
            return image
    except (OSError, ValueError, TypeError, KeyError):
        pass
    return default


def candidates(directory, default):
    images = [default]
    if directory.is_dir():
        images.extend(sorted(
            (p for p in directory.rglob("*") if p.is_file() and
             p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"}),
            key=lambda p: str(p).casefold(),
        ))
    return list(dict.fromkeys(p.resolve() for p in images))


def thumbnail(image):
    """Cache the first frame, invalidate when file content metadata changes."""
    info = image.stat()
    key = hashlib.sha256(
        f"v1:{image}:{info.st_mtime_ns}:{info.st_ctime_ns}:{info.st_size}".encode()
    ).hexdigest()
    cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    directory = cache / "nocturne/wallpaper-thumbnails"
    directory.mkdir(parents=True, exist_ok=True)
    output = directory / f"{key}.png"
    if output.is_file():
        return output
    try:
        with Image.open(image) as source:
            source.seek(0)  # GIFs use their first frame in the picker only.
            preview = ImageOps.fit(
                ImageOps.exif_transpose(source).convert("RGB"), (480, 270),
                method=Image.Resampling.LANCZOS,
            )
    except (OSError, ValueError, UnidentifiedImageError, Image.DecompressionBombError):
        preview = Image.new("RGB", (480, 270), "#191d2d")
        drawing = ImageDraw.Draw(preview)
        drawing.rectangle((160, 60, 320, 190), outline="#8791b1", width=3)
        drawing.text((185, 120), "No preview", fill="#dfe7ff")
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=directory, suffix=".png", delete=False) as out:
            temporary = Path(out.name)
            preview.save(out, format="PNG")
        temporary.replace(output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return output


def menu_rows(images, directory, default):
    with ThreadPoolExecutor(max_workers=4) as pool:
        icons = list(pool.map(thumbnail, images))
    rows = []
    for image, icon in zip(images, icons):
        try:
            label = str(image.relative_to(directory.resolve()))
        except ValueError:
            label = "NOCTURNE (default)" if image == default.resolve() else str(image)
        # Protect rofi's row protocol, including user-supplied directory names.
        label = "".join(" " if ord(c) < 32 or ord(c) == 127 else c for c in label)
        # Omit icons when a custom cache path cannot fit rofi's row protocol.
        if any(ord(c) < 32 or ord(c) == 127 for c in str(icon)):
            rows.append(label)
        else:
            rows.append(f"{label}\0icon\x1f{icon}")
    return "\n".join(rows) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swww", required=True)
    parser.add_argument("--rofi", required=True)
    parser.add_argument("--menu-theme", required=True)
    parser.add_argument("--default", required=True, type=Path)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("action", choices=["restore", "pick", "set"])
    parser.add_argument("image", nargs="?", type=Path)
    args = parser.parse_args()
    if args.action == "restore":
        image = saved_or_default(args.default)
    elif args.action == "set":
        if args.image is None:
            parser.error("set requires an image path")
        image = args.image.expanduser().resolve()
    else:
        images = candidates(args.directory, args.default)
        selection = run(
            [args.rofi, "-no-config", "-dmenu", "-show-icons", "-no-custom", "-i",
             "-format", "i", "-theme", args.menu_theme, "-p", "Wallpaper",
             "-mesg", "Enter: apply    Esc: cancel    Type: search"],
            input=menu_rows(images, args.directory, args.default), text=True, capture_output=True,
        )
        if selection.returncode != 0:
            if selection.returncode == 1 and not selection.stderr.strip():  # Escape
                return 0
            raise RuntimeError(selection.stderr.strip() or "wallpaper menu failed")
        index = int(selection.stdout.strip())
        if index < 0 or index >= len(images):
            raise ValueError("invalid wallpaper selection")
        image = images[index]
    if not image.is_file():
        raise FileNotFoundError(f"wallpaper does not exist: {image}")
    ready(args.swww)
    result = run([args.swww, "img", str(image), "--transition-type", "fade",
                  "--transition-duration", "0.5"], timeout=15)
    if result.returncode and args.action == "restore" and image != args.default:
        print("nocturne-wallpaper: saved image failed; restoring default", file=sys.stderr)
        result = run([args.swww, "img", str(args.default), "--transition-type", "fade",
                      "--transition-duration", "0.5"], timeout=15)
    if result.returncode:
        raise RuntimeError("swww could not apply the image; previous selection retained")
    if args.action != "restore":
        remember(image)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"nocturne-wallpaper: {error}", file=sys.stderr)
        sys.exit(1)
