"""Hyprland monitor editor with independently supervised, reversible previews."""
import argparse
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import uuid

HYPRCTL = "hyprctl"
TIMEOUT = 15
MODE = re.compile(r"^(\d{2,5})x(\d{2,5})@([0-9]+(?:\.[0-9]+)?)(?:Hz)?$")


def query():
    result = subprocess.run([HYPRCTL, "-j", "monitors"], check=True, capture_output=True, text=True, timeout=6)
    return json.loads(result.stdout)


def paths():
    signature = hashlib.sha256(os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "session").encode()).hexdigest()[:12]
    runtime = Path(os.environ["XDG_RUNTIME_DIR"]) / ("nocturne-displays-" + signature)
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "nocturne" / "displays.lua"
    return runtime.with_suffix(".json"), runtime.with_suffix(".lock"), config


def atomic(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as out:
        temp = Path(out.name)
        out.write(content)
    try:
        temp.replace(path)
    finally:
        temp.unlink(missing_ok=True)


def lua(value):
    if isinstance(value, str):
        return '"' + ''.join('\\\\' if c == '\\' else '\\"' if c == '"' else f'\\{ord(c):03d}' if ord(c) < 32 else c for c in value) + '"'
    return str(value).lower()


def rule(row):
    return 'hl.monitor({' + ','.join(k + '=' + lua(v) for k, v in {
        "output": row["name"], "mode": row["mode"], "position": f'{row["x"]}x{row["y"]}',
        "scale": str(row["scale"]), "transform": row["transform"],
    }.items()) + '})'


def apply(rows):
    if not rows:
        return
    result = subprocess.run([HYPRCTL, "eval", '; '.join(rule(row) for row in rows)],
                            check=True, capture_output=True, text=True, timeout=8)
    if result.stdout.strip() != "ok":
        raise RuntimeError(result.stdout.strip() or result.stderr.strip() or "Monitor update failed")


def snapshot(monitors):
    return [{"name": m["name"], "description": m.get("description", ""), "width": m["width"], "height": m["height"],
             "mode": f'{m["width"]}x{m["height"]}@{m["refreshRate"]:.3f}', "hz": m["refreshRate"],
             "x": m["x"], "y": m["y"], "scale": m["scale"], "transform": m.get("transform", 0),
             "availableModes": m.get("availableModes", []), "internal": m["name"].startswith(("eDP", "LVDS", "DSI"))}
            for m in monitors]


def number(value, low, high, integer=False):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not low <= value <= high:
        raise ValueError("Invalid numeric monitor setting")
    if integer and int(value) != value:
        raise ValueError("Coordinates and rotation must be integers")
    return int(value) if integer else value


def validate(rows, current):
    if not isinstance(rows, list) or not 1 <= len(rows) <= 16:
        raise ValueError("Select at least one connected monitor")
    known = {m["name"]: m for m in current}
    if any(not isinstance(r, dict) for r in rows) or {r.get("name") for r in rows} != set(known) or len(rows) != len(known):
        raise ValueError("Connected monitors changed. Reload before applying.")
    clean = []
    for row in rows:
        monitor = known[row["name"]]
        mode = MODE.fullmatch(str(row.get("mode", "")))
        if not mode:
            raise ValueError("Choose a supported resolution and refresh rate")
        w, h, hz = int(mode[1]), int(mode[2]), float(mode[3])
        available = [MODE.fullmatch(v) for v in monitor["availableModes"] + [monitor["mode"]]]
        if not any(m and int(m[1]) == w and int(m[2]) == h and abs(float(m[3]) - hz) < 0.06 for m in available):
            raise ValueError(f'{row["name"]}: unsupported resolution or refresh rate')
        scale = number(row.get("scale"), 0.5, 3)
        if any(abs(n / scale - round(n / scale)) > 0.01 for n in (w, h)):
            raise ValueError(f'{row["name"]}: choose a scale that produces whole logical pixels')
        clean.append({"name": row["name"], "description": monitor["description"], "mode": f"{w}x{h}@{hz:.3f}",
                      "width": w, "height": h, "scale": scale, "transform": number(row.get("transform"), 0, 7, True),
                      "x": number(row.get("x"), -32768, 32768, True), "y": number(row.get("y"), -32768, 32768, True)})
    for i, a in enumerate(clean):
        aw, ah = logical_size(a)
        for b in clean[i+1:]:
            bw, bh = logical_size(b)
            if a["x"] < b["x"] + bw and b["x"] < a["x"] + aw and a["y"] < b["y"] + bh and b["y"] < a["y"] + ah:
                raise ValueError("Monitors overlap. Drag them apart or use a placement button.")
    return clean


def logical_size(row):
    w, h = row["width"], row["height"]
    if row["transform"] % 2:
        w, h = h, w
    return w / row["scale"], h / row["scale"]


def pending():
    path = paths()[0]
    return json.loads(path.read_text()) if path.exists() else None


def rollback(token=None):
    saved = pending()
    if not saved or (token and token != saved["token"]):
        return
    current = {m["name"]: m for m in snapshot(query())}
    # Do not apply a disconnected monitor's old mode to replacement hardware.
    apply([r for r in saved["before"] if r["name"] in current and current[r["name"]]["description"] == r["description"]])
    paths()[0].unlink(missing_ok=True)


def read():
    saved = pending()
    return {"ok": True, "monitors": snapshot(query()), "pending":
            {"token": saved["token"], "remaining": max(0, math.ceil(saved["deadline"] - time.monotonic()))} if saved else None}


def preview(rows):
    if pending():
        raise ValueError("Keep or revert the current preview first")
    before = snapshot(query())
    rows = validate(rows, before)
    token = uuid.uuid4().hex
    atomic(paths()[0], json.dumps({"token": token, "deadline": time.monotonic() + TIMEOUT, "before": before, "after": rows}))
    try:
        # This child survives a Quickshell crash, a closed dialog and a screen change.
        subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "--hyprctl", HYPRCTL, "watchdog", "--token", token],
                         stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        apply(rows)
    except Exception:
        rollback(token)
        raise
    return {"ok": True, "token": token, "remaining": max(0, math.ceil(pending()["deadline"] - time.monotonic()))}


def confirm(token):
    saved = pending()
    if not saved or saved["token"] != token:
        raise ValueError("Preview expired. Reload and try again.")
    if time.monotonic() >= saved["deadline"]:
        rollback(token)
        raise ValueError("Preview expired and was reverted")
    current = {m["name"]: m for m in snapshot(query())}
    for row in saved["after"]:
        actual = current.get(row["name"])
        if not actual or actual["description"] != row["description"] or any(actual[k] != row[k] for k in ("width", "height", "x", "y", "transform")) or abs(actual["scale"]-row["scale"]) > 0.001 or abs(actual["hz"]-float(row["mode"].split('@')[1])) > 0.1:
            raise ValueError("The requested monitor settings were not applied. Revert and reload.")
    config = paths()[2]
    old = []
    if config.exists():
        old = json.loads(config.read_text().splitlines()[0].removeprefix('-- nocturne-displays: '))
    names = {r["name"] for r in saved["after"]}
    rows = [r for r in old if r["name"] not in names] + saved["after"]
    # One atomic file: metadata for this editor and Lua rules for startup/reload/hotplug.
    atomic(config, '-- nocturne-displays: ' + json.dumps(rows, ensure_ascii=True) + '\n'
           + '-- Generated by NOCTURNE Displays. Change settings with Super+P.\n'
           + '\n'.join(rule(r) for r in rows) + '\n')
    paths()[0].unlink(missing_ok=True)
    return {"ok": True}


def watchdog(token):
    # No lock while waiting: UI confirmation and manual rollback must remain responsive.
    while True:
        try:
            with paths()[1].open("a") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                saved = pending()
                if not saved or saved["token"] != token:
                    return
                if time.monotonic() >= saved["deadline"]:
                    rollback(token)
                    return
        except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError):
            # A transient IPC failure must not disarm the rollback watchdog.
            time.sleep(1)
        time.sleep(0.25)


def main():
    global HYPRCTL
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hyprctl", required=True)
    parser.add_argument("action", choices=["read", "preview", "confirm", "revert", "watchdog"])
    parser.add_argument("--plan")
    parser.add_argument("--token")
    args = parser.parse_args()
    HYPRCTL = args.hyprctl
    if args.action == "watchdog":
        watchdog(args.token)
        return
    with paths()[1].open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.action == "read": result = read()
        elif args.action == "preview": result = preview(json.loads(args.plan))
        elif args.action == "confirm": result = confirm(args.token)
        else:
            rollback(args.token)
            result = {"ok": True}
        print(json.dumps(result))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.SubprocessError) as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        sys.exit(1)
