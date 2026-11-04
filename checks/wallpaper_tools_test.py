"""Headless tests with fake clients: state, paths, cancel, readiness, failures."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image

spec = importlib.util.spec_from_file_location("wallpaper", sys.argv.pop())
wallpaper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wallpaper)


class WallpaperTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.directory = self.root / "Wallpapers"
        self.directory.mkdir()
        self.default = self.root / "default.png"
        Image.new("RGB", (90, 60), "red").save(self.default)
        self.image = self.directory / '日本語 space "$(touch NEVER)".png'
        Image.new("RGB", (40, 80), "blue").save(self.image)
        self.calls = []
        self.query_failures = 0
        self.menu_status = 0
        self.image_status = 0
        self.failed_images = set()
        self.menu_input = ""
        self.start_patch = patch.dict(os.environ, {
            "XDG_STATE_HOME": str(self.root / "state"),
            "XDG_CACHE_HOME": str(self.root / "cache"),
        })
        self.start_patch.start()
        self.addCleanup(self.start_patch.stop)

    def fake_run(self, command, **kwargs):
        self.calls.append(command)
        if command[0] == "rofi":
            self.menu_input = kwargs["input"]
            return subprocess.CompletedProcess(command, self.menu_status, "1\n", "")
        if command[1] == "query":
            if self.query_failures:
                self.query_failures -= 1
                return subprocess.CompletedProcess(command, 1)
            return subprocess.CompletedProcess(command, 0)
        return subprocess.CompletedProcess(command, 1 if command[2] in self.failed_images else self.image_status)

    def invoke(self, *action):
        args = ["wallpaper", "--swww", "swww", "--rofi", "rofi", "--menu-theme", "menu.rasi",
                "--default", str(self.default), "--directory", str(self.directory), *action]
        with patch.object(sys, "argv", args), patch.object(wallpaper, "run", self.fake_run), \
                patch.object(wallpaper.time, "sleep"):
            return wallpaper.main()

    def test_select_restore_and_missing_source_fallback(self):
        self.assertEqual(self.invoke("pick"), 0)
        self.assertEqual(json.loads(wallpaper.state_file().read_text())["image"], str(self.image))
        # Shell metacharacters are passed as one literal argv item.
        self.assertEqual(self.calls[-1][2], str(self.image))
        self.assertIn("\0icon\x1f", self.menu_input)
        self.invoke("restore")
        self.assertEqual(self.calls[-1][2], str(self.image))
        self.image.unlink()
        self.invoke("restore")
        self.assertEqual(self.calls[-1][2], str(self.default))

    def test_cancel_and_failure_preserve_selection(self):
        self.invoke("set", str(self.default))
        old = wallpaper.state_file().read_text()
        self.menu_status = 1
        self.invoke("pick")
        self.assertEqual(wallpaper.state_file().read_text(), old)
        self.image_status = 1
        with self.assertRaises(RuntimeError):
            self.invoke("set", str(self.image))
        self.assertEqual(wallpaper.state_file().read_text(), old)

    def test_readiness_retry_and_corrupt_state(self):
        self.query_failures = 2
        self.invoke("restore")
        self.assertEqual(len([c for c in self.calls if c[1] == "query"]), 3)
        wallpaper.state_file().parent.mkdir(parents=True, exist_ok=True)
        wallpaper.state_file().write_text("invalid json")
        self.invoke("restore")
        self.assertEqual(self.calls[-1][2], str(self.default))

    def test_restore_bad_image_falls_back_without_stopping_daemon(self):
        self.invoke("set", str(self.image))
        self.failed_images.add(str(self.image))
        self.assertEqual(self.invoke("restore"), 0)
        self.assertEqual(self.calls[-1][2], str(self.default))

    def test_thumbnails_are_sized_cached_and_invalidated(self):
        cached = wallpaper.thumbnail(self.image)
        with Image.open(cached) as preview:
            self.assertEqual(preview.size, (480, 270))
        previous_time = cached.stat().st_mtime_ns
        self.assertEqual(wallpaper.thumbnail(self.image), cached)
        self.assertEqual(cached.stat().st_mtime_ns, previous_time)
        Image.new("RGB", (100, 100), "green").save(self.image)
        self.assertNotEqual(wallpaper.thumbnail(self.image), cached)

    def test_animated_and_broken_images_have_previews(self):
        animated = self.directory / "animated.gif"
        Image.new("RGB", (20, 20), "red").save(
            animated, save_all=True, append_images=[Image.new("RGB", (20, 20), "blue")],
            duration=100, loop=0,
        )
        with Image.open(wallpaper.thumbnail(animated)) as preview:
            self.assertEqual(preview.getpixel((0, 0)), (255, 0, 0))
        broken = self.directory / "broken.png"
        broken.write_bytes(b"not an image")
        with Image.open(wallpaper.thumbnail(broken)) as preview:
            self.assertEqual(preview.size, (480, 270))

    def test_row_protocol_is_safe_for_control_characters(self):
        odd = self.directory / "line\nmeta\x1finjection.png"
        Image.new("RGB", (20, 20), "red").save(odd)
        images = wallpaper.candidates(self.directory, self.default)
        rows = wallpaper.menu_rows(images, self.directory, self.default).splitlines()
        self.assertEqual(len(rows), len(images))
        for row in rows:
            label, icon = row.split("\0icon\x1f")
            self.assertFalse(any(ord(c) < 32 for c in label))
            self.assertTrue(Path(icon).is_file())


unittest.main()
