import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("battery", sys.argv.pop(1))
battery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(battery)


class BatteryTests(unittest.TestCase):
    def test_discharging_estimate_and_horizontal_icon(self):
        value = battery.waybar_status({"IsPresent": True, "Percentage": 68, "State": 2, "TimeToEmpty": 12600})
        self.assertIn("68%", value["text"])
        self.assertIn("\uf241", value["text"])
        self.assertIn("3 h 30 min remaining", value["tooltip"])

    def test_hide_percentage_preserves_tooltip_and_icon(self):
        value = battery.waybar_status({"IsPresent": True, "Percentage": 68, "State": 2}, False)
        self.assertNotIn("%", value["text"])
        self.assertIn("68%", value["tooltip"])
        self.assertIn("\uf241", value["text"])

    def test_charging_not_low_battery_warning(self):
        value = battery.waybar_status({"IsPresent": True, "Percentage": 5, "State": 1, "TimeToFull": 4800})
        self.assertIn("1 h 20 min until full", value["tooltip"])
        self.assertEqual(value["class"], ["charging"])

    def test_unknown_estimate_is_not_zero_minutes(self):
        value = battery.waybar_status({"IsPresent": True, "Percentage": 68, "State": 2, "TimeToEmpty": 0})
        self.assertIn("Estimating", value["tooltip"])
        self.assertNotIn("0 min", value["tooltip"])

    def test_no_battery_and_service_unavailable(self):
        self.assertEqual(battery.waybar_status({"IsPresent": False})["text"], "")
        self.assertEqual(battery.waybar_status({})["class"], "unknown")

    def test_critical_and_full(self):
        self.assertIn("critical", battery.waybar_status({"IsPresent": True, "Percentage": 9, "State": 2})["class"])
        self.assertIn("Fully charged", battery.waybar_status({"IsPresent": True, "Percentage": 100, "State": 4})["tooltip"])

    def test_preference_survives_reload_and_corruption(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state/nocturne/battery.json"
            self.assertTrue(battery.show_percentage(path))
            battery.save_percentage(False, path)
            self.assertFalse(battery.show_percentage(path))
            self.assertEqual(json.loads(path.read_text()), {"showPercentage": False})
            battery.save_percentage(True, path)
            self.assertTrue(battery.show_percentage(path))
            path.write_text('{broken')
            self.assertTrue(battery.show_percentage(path))
            path.write_text('{"showPercentage":"false"}')
            self.assertTrue(battery.show_percentage(path))

    def test_empty_state_home_uses_home_directory(self):
        with patch.dict("os.environ", {"XDG_STATE_HOME": ""}):
            self.assertEqual(battery.preference_path(), Path.home() / ".local/state/nocturne/battery.json")

    def test_percentage_rounding_matches_the_menu(self):
        value = battery.waybar_status({"IsPresent": True, "Percentage": 68.5, "State": 2})
        self.assertEqual(value["percentage"], 69)

    def test_subminute_tooltip_is_valid_markup(self):
        value = battery.waybar_status({"IsPresent": True, "Percentage": 1, "State": 2, "TimeToEmpty": 30})
        self.assertIn("&lt;1 min remaining", value["tooltip"])

    def test_duration_bounds(self):
        self.assertIsNone(battery.duration(float("nan")))
        self.assertIsNone(battery.duration(-1))
        self.assertEqual(battery.duration(30), "<1 min")
        self.assertEqual(battery.duration(3600), "1 h")


unittest.main()
