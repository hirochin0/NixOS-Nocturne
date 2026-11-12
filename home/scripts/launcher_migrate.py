"""Upgrade launcher defaults and apply the requested image/Steam setup once."""
import json
import os
from pathlib import Path
import stat
import sys
import tempfile


def migrate(current, defaults):
    try:
        if current.is_symlink():
            return False
        old = json.loads(current.read_text())
        new = json.loads(defaults.read_text())
        legacy = [{"name": app["name"], "desktopId": app["desktopId"]} for app in new["apps"][:6]]
        previous_parents = [-1, 0, 0, 1, 1, 2, 2, 3, 4, 5]
        previous_tree = [dict(app, parent=parent) for app, parent in zip(new["apps"], previous_parents)]
        apps = old.get("apps")
        if not isinstance(apps, list) or not all(
                isinstance(app, dict) and isinstance(app.get("desktopId"), str) for app in apps):
            return False
        if old.get("_nocturneLauncherRevision", 0) >= 1:
            return False
        # Recognize the previous 10-node defaults as well as the earlier layouts.
        if apps in (legacy, previous_tree, new["apps"][:10]):
            old["apps"] = new["apps"]
            apps = old["apps"]
        old["image"] = new["image"]
        if not any(app["desktopId"] in ("steam", "steam.desktop") for app in apps):
            apps.append({"name": "Steam", "desktopId": "steam",
                         "parent": min(3, len(apps) - 1)})
        old["_nocturneLauncherRevision"] = 1
        with tempfile.NamedTemporaryFile(mode="w", dir=current.parent, delete=False) as output:
            temp = Path(output.name)
            json.dump(old, output, indent=2, ensure_ascii=False)
            output.write("\n")
        try:
            temp.chmod(stat.S_IMODE(current.stat().st_mode))
            os.replace(temp, current)
        finally:
            temp.unlink(missing_ok=True)
        return True
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        return False


if __name__ == "__main__":
    migrate(Path(sys.argv[1]), Path(sys.argv[2]))
