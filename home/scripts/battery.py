"""Waybar battery status and the shared, user-owned percentage preference."""
import asyncio
import html
import json
import math
import os
from pathlib import Path
import signal
import sys
import tempfile


def preference_path():
    return Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "nocturne/battery.json"


def show_percentage(path=None):
    try:
        value = json.loads((path or preference_path()).read_text()).get("showPercentage", True)
        return value if isinstance(value, bool) else True
    except (OSError, ValueError, AttributeError):
        return True


def save_percentage(value, path=None):
    target = path or preference_path()
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=target.parent, delete=False) as file:
        temporary = Path(file.name)
        json.dump({"showPercentage": value}, file)
    try:
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)


def refresh_waybar():
    for process in Path("/proc").glob("[0-9]*"):
        try:
            if process.stat().st_uid == os.getuid() and (process / "comm").read_text().strip() == "waybar":
                os.kill(int(process.name), signal.SIGRTMIN + 9)
        except (OSError, ValueError):
            pass


async def upower_properties():
    from dbus_next import BusType, Message, MessageType
    from dbus_next.aio import MessageBus
    bus = None
    try:
        bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
        response = await bus.call(Message(
            destination="org.freedesktop.UPower",
            path="/org/freedesktop/UPower/devices/DisplayDevice",
            interface="org.freedesktop.DBus.Properties",
            member="GetAll", signature="s", body=["org.freedesktop.UPower.Device"],
        ))
        if response.message_type == MessageType.ERROR:
            return {}
        return {key: value.value for key, value in response.body[0].items()}
    finally:
        if bus is not None:
            bus.disconnect()


def duration(seconds):
    if not isinstance(seconds, (int, float)) or not math.isfinite(seconds) or seconds <= 0:
        return None
    minutes = int(seconds // 60)
    if minutes == 0:
        return "<1 min"
    hours, minutes = divmod(minutes, 60)
    return (f"{hours} h" + (f" {minutes} min" if minutes else "")) if hours else f"{minutes} min"


def waybar_status(properties, percentage=True):
    if not properties:
        return {"text": "—", "tooltip": "Battery information unavailable", "class": "unknown"}
    if not properties.get("IsPresent", False):
        return {"text": "", "tooltip": "No battery detected", "class": "absent"}
    raw = properties.get("Percentage", 0)
    capacity = max(0, min(100, math.floor(raw + 0.5))) if isinstance(raw, (int, float)) and math.isfinite(raw) else 0
    icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
    index = 4 if capacity >= 90 else 3 if capacity >= 60 else 2 if capacity >= 40 else 1 if capacity >= 15 else 0
    text = f'<span size="18000">{icons[index]}</span>'
    if percentage:
        text += f"  {capacity}%"
    state = properties.get("State", 0)
    classes = []
    if state == 1:
        classes.append("charging")
        time = duration(properties.get("TimeToFull"))
        status = f"{time} until full" if time else "Charging · estimating time"
    elif state == 4:
        classes.append("full")
        status = "Fully charged"
    elif state == 2:
        time = duration(properties.get("TimeToEmpty"))
        status = f"{time} remaining" if time else "Estimating remaining time"
        if capacity <= 12:
            classes.append("critical")
        elif capacity <= 25:
            classes.append("warning")
    else:
        status = "Plugged in" if state == 5 else "Battery"
    return {"text": text, "tooltip": html.escape(f"Battery: {capacity}%\n{status}\nClick: power settings", quote=False), "class": classes, "percentage": capacity}


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "get-percentage":
        print("true" if show_percentage() else "false")
    elif command == "set-percentage":
        if len(sys.argv) != 3 or sys.argv[2] not in ("true", "false"):
            raise SystemExit("Usage: nocturne-battery set-percentage true|false")
        save_percentage(sys.argv[2] == "true")
        refresh_waybar()
    elif command == "status":
        async def query():
            return await asyncio.wait_for(upower_properties(), timeout=3)
        try:
            properties = asyncio.run(query())
        except Exception:
            properties = {}
        print(json.dumps(waybar_status(properties, show_percentage()), ensure_ascii=False))
    else:
        raise SystemExit("Unknown battery command")


if __name__ == "__main__":
    main()
