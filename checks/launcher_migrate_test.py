import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("migration", sys.argv.pop(1))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
defaults = Path(sys.argv.pop(1))
new = json.loads(defaults.read_text())
legacy = [{"name": app["name"], "desktopId": app["desktopId"]} for app in new["apps"][:6]]

class MigrationTest(unittest.TestCase):
    def test_upgrade_defaults_retains_image_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "launcher.json"
            path.write_text(json.dumps({"image": "/home/user/my-image.png", "apps": legacy}))
            self.assertTrue(module.migrate(path, defaults))
            result = json.loads(path.read_text())
            self.assertEqual(result["image"], "/home/user/my-image.png")
            self.assertEqual(len(result["apps"]), 10)
            self.assertFalse(module.migrate(path, defaults))

    def test_custom_invalid_and_symlink_configs_are_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "launcher.json"
            for contents in [json.dumps({"apps": [{"desktopId": "custom"}]}), "invalid"]:
                path.write_text(contents)
                self.assertFalse(module.migrate(path, defaults))
                self.assertEqual(path.read_text(), contents)
            link = Path(tmp) / "link.json"
            link.symlink_to(path)
            self.assertFalse(module.migrate(link, defaults))
            self.assertTrue(link.is_symlink())

unittest.main()
