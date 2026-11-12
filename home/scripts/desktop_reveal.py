"""Transactional desktop reveal; never move or float existing tiled windows."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid

PREFIX = "NocturneDesktop-"


def query(command):
    result = subprocess.run([HYPRCTL, "-j", command], capture_output=True, text=True, timeout=4, check=True)
    return json.loads(result.stdout)


def lua_string(value):
    return '"' + ''.join('\\\\' if c == '\\' else '\\"' if c == '"' else
                         f'\\{ord(c):03d}' if ord(c) < 32 else c for c in str(value)) + '"'


def dispatch(commands):
    # Each argument is Lua-escaped and sent directly as argv, never through a shell.
    code = 'local function run(d) local r=hl.dispatch(d); if r and (r.ok==false or r.success==false) then error(r.error or r.message or "dispatch failed") end end; '
    code += '; '.join('run(' + command + ')' for command in commands)
    result = subprocess.run([HYPRCTL, "eval", code], capture_output=True, text=True, timeout=6, check=True)
    if result.stdout.strip() != "ok":
        raise RuntimeError(result.stdout.strip() or result.stderr.strip() or "Hyprland dispatch failed")


def address(client):
    value = client.get("address", "")
    if not re.fullmatch(r"0x[0-9a-fA-F]+", value):
        raise ValueError("invalid window address")
    return "address:" + value


def workspace_selector(name):
    return name if re.fullmatch(r"[1-9][0-9]*", name) else "name:" + name


def journal_path():
    instance = hashlib.sha256(os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "test").encode()).hexdigest()[:12]
    return Path(os.environ["XDG_RUNTIME_DIR"]) / ("nocturne-desktop-" + instance + ".json")


def save(plan):
    path = journal_path()
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
        temp = Path(output.name)
        json.dump(plan, output)
    try:
        temp.replace(path)
    finally:
        temp.unlink(missing_ok=True)


def inspect():
    monitors, clients = query("monitors"), query("clients")
    monitor = next((m for m in monitors if m.get("focused")), None)
    if not monitor:
        raise RuntimeError("No focused monitor")
    if monitor.get("specialWorkspace", {}).get("name"):
        raise RuntimeError("Close the special workspace before showing the desktop")
    origin = monitor["activeWorkspace"]["name"]
    if origin.startswith(PREFIX):
        raise RuntimeError("Already on the desktop workspace; restore first")
    target = PREFIX + monitor["name"]
    if any(c.get("workspace", {}).get("name") == target for c in clients):
        raise RuntimeError("Desktop workspace is occupied")
    visible = [c for c in clients if c.get("mapped", True) and not c.get("hidden", False)
               and c.get("monitor") == monitor["id"]
               and (c.get("workspace", {}).get("name") == origin or c.get("pinned", False))]
    visible.sort(key=lambda c: c.get("focusHistoryID", 1000), reverse=True)
    focused = next((c["address"] for c in visible if c.get("focusHistoryID") == 0), "")
    settle = 750
    try:
        animations = query("animations")
        nodes = animations[0] if isinstance(animations, list) and animations and isinstance(animations[0], list) else []
        speeds = [float(a["speed"]) for a in nodes if a.get("name", "").startswith("workspaces") and a.get("enabled")]
        if speeds:
            settle = min(2500, max(100, round(max(speeds) * 100 + 100)))
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        pass
    return {"token": uuid.uuid4().hex, "monitor": monitor["name"], "monitorX": monitor["x"], "monitorY": monitor["y"],
            "origin": origin, "target": target, "focused": focused, "windows": visible, "settleMs": settle}


def show(plan):
    if journal_path().exists():
        raise RuntimeError("An existing desktop transaction needs recovery")
    monitors, clients = query("monitors"), query("clients")
    monitor = next((m for m in monitors if m["name"] == plan["monitor"]), None)
    if not monitor or not monitor.get("focused") or monitor["activeWorkspace"]["name"] != plan["origin"]:
        raise RuntimeError("Workspace changed while capturing")
    if any(c.get("workspace", {}).get("name") == plan["target"] for c in clients):
        raise RuntimeError("Desktop workspace is occupied")
    known = {c["address"]: c for c in clients}
    commands = []
    for saved in plan["windows"]:
        current = known.get(saved["address"])
        if saved.get("pinned") and current and current.get("pinned"):
            commands.append('hl.dsp.window.pin({window=' + lua_string(address(current)) + ',action="disable"})')
    commands += ['hl.dsp.focus({monitor=' + lua_string(plan["monitor"]) + '})',
                 'hl.dsp.focus({workspace=' + lua_string(workspace_selector(plan["target"])) + '})']
    save(plan)  # Recovery remains possible if dispatch or the shell fails midway.
    dispatch(commands)
    return {"ok": True}


def restore(token=None, focus=True):
    path = journal_path()
    if not path.exists():
        return {"ok": True}
    plan = json.loads(path.read_text())
    if token and plan["token"] != token:
        return {"ok": True}
    monitors, clients = query("monitors"), query("clients")
    monitor = next((m for m in monitors if m["name"] == plan["monitor"]), None)
    still_desktop = monitor and monitor["activeWorkspace"]["name"] == plan["target"]
    known = {c["address"]: c for c in clients}
    commands = []
    # Applications launched from a desktop widget join the original workspace.
    for client in clients:
        if client.get("workspace", {}).get("name") == plan["target"]:
            commands.append('hl.dsp.window.move({window=' + lua_string(address(client)) + ',workspace='
                            + lua_string(workspace_selector(plan["origin"])) + ',follow=false})')
    if focus and still_desktop:
        commands += ['hl.dsp.focus({monitor=' + lua_string(plan["monitor"]) + '})',
                     'hl.dsp.focus({workspace=' + lua_string(workspace_selector(plan["origin"])) + '})']
    for saved in plan["windows"]:
        current = known.get(saved["address"])
        if saved.get("pinned") and current and current.get("pid") == saved.get("pid"):
            commands.append('hl.dsp.window.pin({window=' + lua_string(address(current)) + ',action="enable"})')
    opened_focus = next((c["address"] for c in clients if c.get("workspace", {}).get("name") == plan["target"] and c.get("focusHistoryID") == 0), plan["focused"])
    if focus and still_desktop and opened_focus in known:
        commands.append('hl.dsp.focus({window=' + lua_string(address(known[opened_focus])) + '})')
    if focus and still_desktop and monitor and not monitor.get("focused"):
        previous_monitor = next((m for m in monitors if m.get("focused")), None)
        if previous_monitor:
            commands.append('hl.dsp.focus({monitor=' + lua_string(previous_monitor["name"]) + '})')
    if commands:
        dispatch(commands)
    path.unlink(missing_ok=True)
    return {"ok": True}


def state(token):
    plan = json.loads(journal_path().read_text())
    if plan["token"] != token:
        return {"active": False}
    monitors, clients = query("monitors"), query("clients")
    monitor = next((m for m in monitors if m["name"] == plan["monitor"]), None)
    active = bool(monitor and monitor["activeWorkspace"]["name"] == plan["target"])
    opened = any(c.get("workspace", {}).get("name") == plan["target"] for c in clients)
    return {"active": active, "opened": opened}


HYPRCTL = "hyprctl"
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hyprctl", required=True)
    parser.add_argument("action", choices=["inspect", "show", "restore", "state"])
    parser.add_argument("--plan")
    parser.add_argument("--token")
    parser.add_argument("--no-focus", action="store_true")
    args = parser.parse_args()
    HYPRCTL = args.hyprctl
    try:
        lock = journal_path().with_suffix(".lock")
        with lock.open("w") as stream:
            fcntl.flock(stream, fcntl.LOCK_EX)
            result = inspect() if args.action == "inspect" else show(json.loads(args.plan)) if args.action == "show" else state(args.token) if args.action == "state" else restore(args.token, not args.no_focus)
        print(json.dumps(result))
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        sys.exit(1)
