import copy
import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("desktop", sys.argv.pop())
desktop = importlib.util.module_from_spec(spec)
spec.loader.exec_module(desktop)
real_dispatch = desktop.dispatch


class DesktopTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        env = patch.dict(os.environ, {"XDG_RUNTIME_DIR": self.tmp.name, "HYPRLAND_INSTANCE_SIGNATURE": "test-session"})
        env.start(); self.addCleanup(env.stop)
        self.monitor = {"id": 0, "name": "eDP-1", "x": 0, "y": 0, "focused": True,
                        "activeWorkspace": {"name": "1"}, "specialWorkspace": {"name": ""}}
        self.clients = [self.client("0xaaa", "1", 0), self.client("0xbbb", "9", 1, pinned=True),
                        self.client("0xccc", "2", 2), dict(self.client("0xddd", "1", 3), hidden=True)]
        self.calls = []
        mocks = [patch.object(desktop, "query", self.query), patch.object(desktop, "dispatch", self.calls.append)]
        for mock in mocks: mock.start(); self.addCleanup(mock.stop)

    @staticmethod
    def client(addr, workspace, order, **extra):
        return {"address": addr, "pid": int(addr[2:], 16), "monitor": 0, "workspace": {"name": workspace},
                "at": [40, 80], "size": [600, 500], "mapped": True, "hidden": False,
                "pinned": False, "floating": False, "fullscreen": 2 if order == 0 else 0,
                "focusHistoryID": order, **extra}

    def query(self, name):
        return {"monitors": [self.monitor], "clients": self.clients,
                "animations": [[{"name": "workspaces", "speed": 6, "enabled": True}]]}[name]

    def enter(self):
        plan = desktop.inspect()
        desktop.show(plan)
        self.monitor["activeWorkspace"]["name"] = plan["target"]
        return plan

    def test_visible_selection_preserves_layout_and_restores_pins(self):
        before = copy.deepcopy(self.clients)
        plan = self.enter()
        self.assertEqual({w["address"] for w in plan["windows"]}, {"0xaaa", "0xbbb"})
        self.assertTrue(desktop.journal_path().exists())
        self.assertEqual(plan["settleMs"], 700)
        self.assertTrue(desktop.state(plan["token"])["active"])
        desktop.restore(plan["token"])
        self.assertFalse(desktop.journal_path().exists())
        self.assertIn('action="disable"', str(self.calls[0]))
        self.assertIn('action="enable"', str(self.calls[-1]))
        self.assertNotIn('window.float', str(self.calls))
        self.assertNotIn('fullscreen', str(self.calls))
        self.assertEqual(self.clients, before)

    def test_new_app_returns_to_original_workspace_and_keeps_focus(self):
        plan = self.enter()
        for c in self.clients: c["focusHistoryID"] += 1
        self.clients.append(self.client("0xeee", plan["target"], 0))
        self.assertTrue(desktop.state(plan["token"])["opened"])
        desktop.restore(plan["token"])
        commands = self.calls[-1]
        self.assertTrue(any('window.move' in c and 'address:0xeee' in c and 'workspace="1"' in c for c in commands))
        self.assertIn('address:0xeee', commands[-1])

    def test_navigation_monitor_loss_and_closed_windows(self):
        plan = self.enter()
        self.monitor["activeWorkspace"]["name"] = "3"
        self.clients = []
        self.assertFalse(desktop.state(plan["token"])["active"])
        desktop.restore(plan["token"], False)
        self.assertEqual(len(self.calls), 1, 'should not steal selected workspace')
        self.monitor["activeWorkspace"]["name"] = "1"
        plan = self.enter()
        with patch.object(desktop, "query", side_effect=lambda name: []):
            desktop.restore(plan["token"])
        self.assertFalse(desktop.journal_path().exists())

    def test_failure_leaves_recoverable_journal_and_wrong_token_is_noop(self):
        plan = desktop.inspect()
        with patch.object(desktop, "dispatch", side_effect=RuntimeError("IPC failed")):
            with self.assertRaises(RuntimeError): desktop.show(plan)
        self.assertTrue(desktop.journal_path().exists())
        desktop.restore("stale-token")
        self.assertTrue(desktop.journal_path().exists())
        desktop.restore()
        self.assertFalse(desktop.journal_path().exists())

    def test_refuse_special_occupied_or_changed_workspace(self):
        self.monitor["specialWorkspace"]["name"] = "special:tools"
        with self.assertRaises(RuntimeError): desktop.inspect()
        self.monitor["specialWorkspace"]["name"] = ""
        plan = desktop.inspect()
        self.monitor["activeWorkspace"]["name"] = "2"
        with self.assertRaises(RuntimeError): desktop.show(plan)
        self.assertFalse(desktop.journal_path().exists())
        self.monitor["activeWorkspace"]["name"] = "1"
        self.clients.append(self.client("0xfff", plan["target"], 4))
        with self.assertRaises(RuntimeError): desktop.inspect()

    def test_dispatch_checks_lua_ok_failures(self):
        import subprocess
        with patch.object(desktop.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "ok\n", "")) as run:
            real_dispatch(['hl.dsp.focus({workspace="1"})'])
            args = run.call_args.args[0]
            self.assertIn("r.ok==false", args[-1])
            self.assertNotIn("shell", run.call_args.kwargs)
        with patch.object(desktop.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "Lua error: refused", "")):
            with self.assertRaises(RuntimeError): real_dispatch(['hl.dsp.focus({workspace="1"})'])

    def test_lua_escaping_and_session_isolation(self):
        self.assertEqual(desktop.lua_string('x"\\\n'), '"x\\"\\\\\\010"')
        with self.assertRaises(ValueError): desktop.address({"address": "0xaaa; evil()"})
        previous = desktop.journal_path()
        with patch.dict(os.environ, {"HYPRLAND_INSTANCE_SIGNATURE": "other-session"}):
            self.assertNotEqual(desktop.journal_path(), previous)


unittest.main()
