"""User-owned Spotify + pinned Marketplace; never modify the Nix store."""
import fcntl
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


def writable_copy(source, target):
    shutil.copytree(source, target, symlinks=False)
    for path in [target, *target.rglob("*")]:
        path.chmod(path.stat().st_mode | 0o200)


def prepare_client(source, target):
    writable_copy(source / "share/spotify", target)
    wrapper = target / "spotify"
    original = str(source / "share/spotify/.spotify-wrapped")
    text = wrapper.read_text()
    # Preserve upstream GTK/Wayland/LD_LIBRARY_PATH setup. Only redirect exec.
    quoted = '"' + original + '"'
    if quoted not in text:
        raise RuntimeError("Spotify wrapper format changed; refusing to patch it")
    wrapper.write_text(text.replace(quoted, shlex.quote(str(target / ".spotify-wrapped"))))


def notify(settings, message):
    print(message, file=sys.stderr)
    subprocess.run([settings["notify"], "Spotify / Spicetify", message], check=False)


def running_client(root):
    for proc in Path("/proc").glob("[0-9]*"):
        try:
            if (proc / "exe").resolve().is_relative_to(root):
                return True
        except (OSError, RuntimeError):
            pass
    return False


def main():
    settings = json.loads(Path(sys.argv[1]).read_text())
    mode, *args = sys.argv[2:]
    home = Path.home()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    data_home = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))
    root = data_home / "nocturne/spotify"
    config = config_home / "spicetify-nocturne"
    prefs = config_home / "spotify/prefs"
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    config.mkdir(parents=True, exist_ok=True, mode=0o700)
    env = dict(os.environ, SPICETIFY_CONFIG=str(config))
    if mode == "cli" and args and args[0] in ("--version", "-v", "--help", "-h"):
        os.execve(settings["cli"], ["spicetify", *args], env)
    marker = root / "ready.json"
    client = root / "client"
    desired = {key: settings[key] for key in ("spotify", "cli", "marketplace")}

    def spice(*commands):
        subprocess.run([settings["cli"], "--no-restart", *commands], env=env, check=True)

    with (root / "setup.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        ready = json.loads(marker.read_text()) if marker.exists() else None
        if ready != desired:
            if running_client(root):
                notify(settings, "Spotifyを完全に終了してから、もう一度起動してください。")
                return 1
            if not prefs.exists():
                notify(settings, "初回のSpotifyを開きます。ログイン後、完全に終了して再起動するとMarketplaceが有効になります。")
                if mode == "cli":
                    return 1
                os.execv(settings["spotify"] + "/bin/spotify", ["spotify", *args])
            if marker.exists():
                marker.unlink()
            if client.exists():
                shutil.rmtree(client)
            prepare_client(Path(settings["spotify"]), client)
            app = config / "CustomApps/marketplace"
            if app.exists():
                shutil.rmtree(app)
            app.parent.mkdir(exist_ok=True)
            writable_copy(Path(settings["marketplace"]), app)
            ini = config / "config-xpui.ini"
            first = not ini.exists()
            spice("config", "spotify_path", str(client), "prefs_path", str(prefs))
            if first:
                nocturne = config / "Themes/Nocturne"
                nocturne.parent.mkdir(exist_ok=True)
                writable_copy(Path(settings["theme"]), nocturne)
                shutil.copyfile(settings["colors"], nocturne / "color.ini")
                spice("config", "current_theme", "Nocturne", "color_scheme", "Nocturne",
                      "inject_css", "1", "replace_colors", "1")
            spice("config", "custom_apps", "marketplace")
            # The copy above is pristine. Old-version backups must not be restored.
            spice("clear")
            spice("backup", "apply")
            if not (client / "Apps/xpui/spicetify-routes-marketplace.js").is_file():
                raise RuntimeError("Marketplace injection did not complete")
            marker.write_text(json.dumps(desired))
    if mode == "cli":
        os.execve(settings["cli"], ["spicetify", *args], env)
    os.execve(str(client / "spotify"), ["spotify", *args], env)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError, ValueError) as error:
        print(f"Spotify setup failed: {error}", file=sys.stderr)
        sys.exit(1)
