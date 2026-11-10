"""Extend only the untouched six-app default list, preserving user image/settings."""
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
        if old.get("apps") != legacy:
            return False
        old["apps"] = new["apps"]
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
