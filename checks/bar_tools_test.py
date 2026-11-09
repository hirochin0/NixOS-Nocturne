import importlib.util
import sys
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("bar", sys.argv.pop())
bar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bar)

class BarStatusTest(unittest.TestCase):
    def test_wifi_volume_and_backlight(self):
        def query(args):
            if "DEVICE,TYPE,STATE,CONNECTION" in args:
                return "wlan0:wifi:connected:Home\\:WiFi"
            if "IP4.ADDRESS" in args:
                return "192.168.1.5/24"
            if "IN-USE,SIGNAL" in args:
                return ":10\n*:85"
            if args[0] == "wpctl":
                return "Volume: 0.75 [MUTED]"
            if args[0] == "brightnessctl":
                return "amdgpu_bl1,backlight,100,40%,255"
            return ""
        with patch.object(bar, "query", side_effect=query):
            data = bar.status()
        self.assertEqual(data["network"], "󰖩 85%")
        self.assertIn("Home:WiFi", data["networkDetail"])
        self.assertIn("192.168.1.5/24", data["networkDetail"])
        self.assertEqual(data["audio"], "󰖁 Mute")
        self.assertEqual(data["brightness"], "40%")

    def test_unavailable_services(self):
        with patch.object(bar, "query", return_value=""):
            data = bar.status()
        self.assertEqual(data["network"], "󰖪 Offline")
        self.assertEqual(data["audio"], "󰕾 —")
        self.assertEqual(data["brightness"], "—")

unittest.main()
