"""Small bounded CLI queries for the Quickshell bar; no shell interpolation."""
import calendar
import datetime
import json
import os
import re
import subprocess
import sys


def query(args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=1,
                              env={**os.environ, "LC_ALL": "C"}).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def status():
    network, detail = "󰖪 Offline", "Network unavailable"
    for line in query(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]).splitlines():
        fields = line.split(":", 3)
        if len(fields) == 4 and fields[2] == "connected" and fields[1] in ("wifi", "ethernet"):
            network = "󰈀 LAN" if fields[1] == "ethernet" else "󰖩 Wi-Fi"
            detail = fields[3].replace("\\:", ":") + " · " + fields[0]
            address = query(["nmcli", "-g", "IP4.ADDRESS", "device", "show", fields[0]])
            if address:
                detail += " · " + address.splitlines()[0]
            if fields[1] == "wifi":
                for wifi in query(["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]).splitlines():
                    if wifi.startswith("*:"):
                        network = "󰖩 " + wifi.split(":")[1] + "%"
                        break
            break
    volume = query(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    match = re.search(r"Volume:\s*([0-9.]+)", volume)
    audio = "󰖁 Mute" if "MUTED" in volume else "󰕾 " + str(round(float(match[1]) * 100)) + "%" if match else "󰕾 —"
    brightness = query(["brightnessctl", "--class=backlight", "-m"]).split(",")
    now = datetime.datetime.now()
    return dict(network=network, networkDetail=detail, audio=audio,
                brightness=brightness[3] if len(brightness) > 3 else "—",
                calendar=calendar.month(now.year, now.month))


actions = {
    "launcher": ["nocturne-launcher"], "session": ["nocturne-power"],
    "network": ["nm-connection-editor"], "audio": ["pavucontrol"],
    "mute": ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"],
    "volume-up": ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"],
    "volume-down": ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"],
    "brightness-up": ["brightnessctl", "--class=backlight", "--min-value=1", "set", "+5%"],
    "brightness-down": ["brightnessctl", "--class=backlight", "--min-value=1", "set", "5%-"],
}
if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    if action == "status":
        print(json.dumps(status(), ensure_ascii=False))
    elif action in actions:
        os.execvp(actions[action][0], actions[action])
    else:
        raise SystemExit("Unknown bar action")
