"""Fetch and cache line-synced LRCLIB lyrics for the current MPRIS track."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import tempfile
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

USER_AGENT = "Nocturne/1.0 (https://github.com/hirochin0/NixOS-Nocturne)"


def lookup(title, artist, album, duration, opener=urlopen):
    if not title.strip() or not artist.strip():
        return {"status": "missing"}
    params = {"track_name": title, "artist_name": artist}
    if album:
        params["album_name"] = album
    if 1 <= duration <= 3600:
        params["duration"] = round(duration)
    key = hashlib.sha256(json.dumps(params, sort_keys=True).encode()).hexdigest()
    cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "nocturne/lyrics" / (key + ".json")
    try:
        saved = json.loads(cache.read_text())
        result = saved["result"]
        if result.get("status") not in ("synced", "unsynced", "instrumental", "missing"):
            raise ValueError("invalid cache status")
        if result["status"] == "synced" and not isinstance(result.get("syncedLyrics"), str):
            raise ValueError("invalid cached lyrics")
        lifetime = 30 * 86400 if saved["result"]["status"] in ("synced", "instrumental") else 6 * 3600
        if 0 <= time.time() - saved["time"] < lifetime:
            return saved["result"]
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        pass
    result = {"status": "missing"}
    try:
        # A different album release may share the same title, artist and duration.
        attempts = [params]
        if album:
            attempts.append({k: v for k, v in params.items() if k != "album_name"})
        for index, query in enumerate(attempts):
            try:
                request = Request("https://lrclib.net/api/get?" + urlencode(query),
                                  headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
                with opener(request, timeout=8) as response:
                    raw = response.read(1_000_001)
                if len(raw) > 1_000_000:
                    return {"status": "offline"}
                record = json.loads(raw)
                if not isinstance(record, dict):
                    return {"status": "offline"}
                synced = record.get("syncedLyrics")
                if record.get("instrumental") is True:
                    result = {"status": "instrumental"}
                elif isinstance(synced, str) and synced.strip():
                    result = {"status": "synced", "syncedLyrics": synced}
                else:
                    result = {"status": "unsynced"}
                break
            except HTTPError as error:
                if error.code != 404:
                    return {"status": "offline"}
                if index + 1 == len(attempts):
                    result = {"status": "missing"}
    except (OSError, ValueError, URLError, socket.timeout):
        return {"status": "offline"}
    temporary = None
    try:
        cache.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=cache.parent, delete=False) as output:
            temporary = Path(output.name)
            json.dump({"time": time.time(), "result": result}, output, ensure_ascii=False)
        temporary.replace(cache)
    except OSError:
        pass  # An unwritable cache must not hide successfully retrieved lyrics.
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--title", required=True)
    parser.add_argument("--artist", required=True)
    parser.add_argument("--album", default="")
    parser.add_argument("--duration", type=float, default=0)
    args = parser.parse_args()
    print(json.dumps(lookup(args.title, args.artist, args.album, args.duration), ensure_ascii=False))
