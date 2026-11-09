"""Resolve desktop-entry icons from the user's actual XDG application paths."""
import configparser
import json
import os
from pathlib import Path


def catalog():
    home = Path.home()
    roots = [Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))]
    roots += [Path(p) for p in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if p]
    roots += [home / ".nix-profile/share", Path("/etc/profiles/per-user") / os.environ.get("USER", "") / "share",
              Path("/run/current-system/sw/share"), home / ".local/share/flatpak/exports/share",
              Path("/var/lib/flatpak/exports/share")]
    roots = list(dict.fromkeys(roots))
    entries, icons, themed_icons, seen = [], {}, {}, set()
    for root in roots:
        applications = root / "applications"
        for path in sorted(applications.rglob("*.desktop")) if applications.is_dir() else []:
            entry_id = str(path.relative_to(applications)).replace("/", "-")[:-8]
            if entry_id in seen:
                continue
            seen.add(entry_id)
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                parser.read(path, encoding="utf-8")
                entry = parser["Desktop Entry"]
                if entry.get("Hidden", "false").lower() == "true":
                    continue
                entries.append(dict(id=entry_id, name=entry.get("Name", ""),
                                    startupClass=entry.get("StartupWMClass", ""), icon=entry.get("Icon", "")))
            except (OSError, UnicodeError, configparser.Error, KeyError):
                continue
        # Original application assets beat theme replacements, even if a theme
        # is found in an earlier XDG root. Prefer scalable/high resolution files.
        sizes = ["scalable", "512x512", "256x256", "128x128", "96x96", "64x64", "48x48", "32x32", "24x24", "22x22", "16x16", "symbolic"]
        patterns = ["icons/hicolor/" + size + "/apps/*" for size in sizes] + ["pixmaps/*", "icons/*"]
        for target, globs in [(icons, patterns), (themed_icons, ["icons/*/*/apps/*", "icons/*/apps/*"])]:
            for pattern in globs:
                for path in sorted(root.glob(pattern)):
                    if path.suffix.lower() in (".svg", ".png", ".xpm") and path.is_file():
                        target.setdefault(path.stem, str(path))
                        target.setdefault(path.stem.lower(), str(path))
    for name, path in themed_icons.items():
        icons.setdefault(name, path)
    return dict(entries=entries, icons=icons)


if __name__ == "__main__":
    print(json.dumps(catalog(), ensure_ascii=False))
