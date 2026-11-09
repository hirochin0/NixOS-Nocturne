import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
spec = importlib.util.spec_from_file_location("catalog", sys.argv.pop())
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
class CatalogTest(unittest.TestCase):
    def test_user_desktop_and_icon_take_priority(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for folder in ["user/applications", "system/applications", "user/icons/hicolor/48x48/apps"]:
                (root / folder).mkdir(parents=True)
            (root / "user/applications/custom.desktop").write_text("[Desktop Entry]\nName=Custom\nStartupWMClass=CustomWindow\nIcon=custom-logo\n")
            (root / "system/applications/custom.desktop").write_text("[Desktop Entry]\nName=Wrong\nIcon=wrong\n")
            image = root / "user/icons/hicolor/48x48/apps/custom-logo.svg"
            image.write_text('<svg xmlns="http://www.w3.org/2000/svg"/>')
            with patch.dict(os.environ, {"HOME": temp, "XDG_DATA_HOME": str(root / "user"), "XDG_DATA_DIRS": str(root / "system")}):
                result = module.catalog()
            entries = [e for e in result["entries"] if e["id"] == "custom"]
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["startupClass"], "CustomWindow")
            self.assertEqual(entries[0]["icon"], "custom-logo")
            self.assertEqual(result["icons"]["custom-logo"], str(image))
    def test_original_icon_beats_earlier_theme(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            theme = root / "user/icons/Papirus/48x48/apps/kitty.svg"
            native = root / "system/icons/hicolor/256x256/apps/kitty.png"
            for path in [theme, native]:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture")
            with patch.dict(os.environ, {"HOME": temp, "XDG_DATA_HOME": str(root / "user"), "XDG_DATA_DIRS": str(root / "system")}):
                result = module.catalog()
            self.assertEqual(result["icons"]["kitty"], str(native))

unittest.main()
