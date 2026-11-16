import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("displays", sys.argv.pop())
d = importlib.util.module_from_spec(spec)
spec.loader.exec_module(d)


class DisplaysTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        env = patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.tmp.name, "XDG_CONFIG_HOME": self.tmp.name,
                                     "HYPRLAND_INSTANCE_SIGNATURE": "display-test"})
        env.start(); self.addCleanup(env.stop)
        self.monitors = [self.monitor("eDP-1", 0), self.monitor("HDMI-A-1", 1920)]
        self.applied = []
        self.popen = patch.object(d.subprocess, "Popen").start(); self.addCleanup(patch.stopall)
        patch.object(d, "query", lambda: copy.deepcopy(self.monitors)).start()
        patch.object(d, "apply", self.apply).start()

    @staticmethod
    def monitor(name, x):
        return {"name": name, "description": name + " panel", "width": 1920, "height": 1080,
                "refreshRate": 60.0, "scale": 1.0, "x": x, "y": 0, "transform": 0,
                "availableModes": ["1920x1080@60.00Hz", "1920x1080@120.00Hz", "1280x720@59.94Hz"]}

    def apply(self, rows):
        self.applied.append(copy.deepcopy(rows))
        for row in rows:
            m = next(m for m in self.monitors if m["name"] == row["name"])
            m.update({k: row[k] for k in ("x", "y", "width", "height", "scale", "transform")})
            m["refreshRate"] = float(row["mode"].split('@')[1])

    def draft(self):
        rows = d.snapshot(self.monitors)
        rows[1].update(mode="1920x1080@120", x=-1920)
        return rows

    def test_preview_confirm_and_atomic_persistence(self):
        result = d.preview(self.draft())
        self.popen.assert_called_once()
        self.assertEqual(result["remaining"], 15)
        self.assertTrue(d.paths()[0].exists())
        self.assertFalse(d.paths()[2].exists(), "Unconfirmed preview must not change startup rules")
        d.confirm(result["token"])
        self.assertFalse(d.paths()[0].exists())
        content = d.paths()[2].read_text()
        saved = json.loads(content.splitlines()[0].removeprefix('-- nocturne-displays: '))
        self.assertEqual(saved[1]["x"], -1920)
        self.assertIn('mode="1920x1080@120.000"', content)
        self.assertIn('position="-1920x0"', content)
        self.assertEqual(d.paths()[2].stat().st_mode & 0o777, 0o600)

    def test_close_or_timeout_restores_all_original_settings(self):
        original = copy.deepcopy(self.monitors)
        result = d.preview(self.draft())
        d.rollback("wrong-token")
        self.assertTrue(d.pending())
        d.rollback(result["token"])
        self.assertEqual(self.monitors, original)
        self.assertFalse(d.pending())
        self.assertFalse(d.paths()[2].exists())

    def test_expired_confirmation_rolls_back(self):
        result = d.preview(self.draft())
        with patch.object(d.time, "monotonic", return_value=d.pending()["deadline"]+1):
            with self.assertRaises(ValueError): d.confirm(result["token"])
        self.assertFalse(d.pending())
        self.assertEqual(self.monitors[1]["x"], 1920)

    def test_unapplied_mode_cannot_be_saved(self):
        result = d.preview(self.draft())
        self.monitors[1]["refreshRate"] = 60
        with self.assertRaises(ValueError): d.confirm(result["token"])
        self.assertFalse(d.paths()[2].exists())
        self.assertTrue(d.pending())

    def test_unsupported_modes_scales_rotation_and_injection(self):
        for patch_values in [{"mode": "3840x2160@240"}, {"mode": '1920x1080@60;error("x")'},
                             {"scale": float('nan')}, {"scale": 1.3}, {"scale": True},
                             {"transform": 8}, {"x": 0.5}, {"x": 999999}]:
            with self.subTest(patch_values=patch_values):
                rows = self.draft(); rows[1].update(patch_values)
                with self.assertRaises(ValueError): d.validate(rows, d.snapshot(self.monitors))
        rows = self.draft(); rows[1].update(mode="1280x720@59.94", x=-1280)
        self.assertEqual(d.validate(rows, d.snapshot(self.monitors))[1]["mode"], "1280x720@59.940")
        self.assertEqual(d.lua('a"\\\n'), '"a\\"\\\\\\010"')

    def test_overlap_uses_rotation_and_logical_scale(self):
        rows = self.draft(); rows[1].update(x=1000, scale=1.5, transform=1)
        with self.assertRaises(ValueError): d.validate(rows, d.snapshot(self.monitors))
        rows[1]["x"] = -720
        clean = d.validate(rows, d.snapshot(self.monitors))
        self.assertEqual(d.logical_size(clean[1]), (720, 1280))

    def test_hotplug_is_rejected_and_rollback_skips_replacement_hardware(self):
        rows = self.draft(); rows.pop()
        with self.assertRaises(ValueError): d.preview(rows)
        d.preview(self.draft())
        self.monitors[1]["description"] = "Different monitor"
        d.rollback()
        self.assertEqual([r["name"] for r in self.applied[-1]], ["eDP-1"])

    def test_spawn_failure_restores_and_failed_rollback_keeps_journal(self):
        self.popen.side_effect = OSError("spawn failed")
        with self.assertRaises(OSError): d.preview(self.draft())
        self.assertFalse(d.pending())
        self.popen.side_effect = None
        result = d.preview(self.draft())
        with patch.object(d, "apply", side_effect=RuntimeError("IPC failed")):
            with self.assertRaises(RuntimeError): d.rollback(result["token"])
        self.assertTrue(d.pending())

    def test_watchdog_retries_transient_errors_then_reverts(self):
        result = d.preview(self.draft())
        real_rollback = d.rollback
        calls = []
        def rollback(token):
            calls.append(token)
            if len(calls) == 1: raise RuntimeError("temporary IPC failure")
            real_rollback(token)
        with patch.object(d.time, "monotonic", return_value=d.pending()["deadline"]+1), \
             patch.object(d.time, "sleep"), patch.object(d, "rollback", rollback):
            d.watchdog(result["token"])
        self.assertEqual(len(calls), 2)
        self.assertFalse(d.pending())

    def test_saved_disconnected_profiles_survive_other_monitor_edits(self):
        result = d.preview(self.draft()); d.confirm(result["token"])
        self.monitors.pop()
        result = d.preview(d.snapshot(self.monitors)); d.confirm(result["token"])
        saved = json.loads(d.paths()[2].read_text().splitlines()[0].removeprefix('-- nocturne-displays: '))
        self.assertEqual({r["name"] for r in saved}, {"eDP-1", "HDMI-A-1"})


unittest.main()
