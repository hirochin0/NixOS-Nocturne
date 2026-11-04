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
        self.default.write_bytes(b"default fixture")
        self.image = self.directory / '日本語 space "$(touch NEVER)".png'
        self.image.write_bytes(b"image fixture")
        self.calls = []
        self.query_failures = 0
        self.menu_status = 0
        self.image_status = 0
        self.failed_images = set()
        self.start_patch = patch.dict(os.environ, {"XDG_STATE_HOME": str(self.root / "state")})
        self.start_patch.start()
        self.addCleanup(self.start_patch.stop)

    def fake_run(self, command, **kwargs):
        self.calls.append(command)
        if command[0] == "fuzzel":
            return subprocess.CompletedProcess(command, self.menu_status, "1\n", "")
        if command[1] == "query":
            if self.query_failures:
                self.query_failures -= 1
                return subprocess.CompletedProcess(command, 1)
            return subprocess.CompletedProcess(command, 0)
        return subprocess.CompletedProcess(command, 1 if command[2] in self.failed_images else self.image_status)

    def invoke(self, *action):
        args = ["wallpaper", "--swww", "swww", "--fuzzel", "fuzzel",
                "--default", str(self.default), "--directory", str(self.directory), *action]
        with patch.object(sys, "argv", args), patch.object(wallpaper, "run", self.fake_run), \
                patch.object(wallpaper.time, "sleep"):
            return wallpaper.main()

    def test_select_restore_and_missing_source_fallback(self):
        self.assertEqual(self.invoke("pick"), 0)
        self.assertEqual(json.loads(wallpaper.state_file().read_text())["image"], str(self.image))
        # Shell metacharacters are passed as one literal argv item.
        self.assertEqual(self.calls[-1][2], str(self.image))
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


unittest.main()
