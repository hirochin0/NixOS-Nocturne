import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlsplit

spec = importlib.util.spec_from_file_location("lyrics", sys.argv.pop())
lyrics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lyrics)


class LyricsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        env = patch.dict(os.environ, {"XDG_CACHE_HOME": self.tmp.name})
        env.start(); self.addCleanup(env.stop)
        self.calls = []
        self.record = {"syncedLyrics": "[00:01.00]Test phrase\n[00:03.50]Second phrase"}

    def open(self, request, timeout):
        self.calls.append(request)
        self.assertEqual(timeout, 8)
        self.assertIn("Nocturne/", request.get_header("User-agent"))
        return io.BytesIO(json.dumps(self.record).encode())

    def fetch(self, opener=None, **kwargs):
        return lyrics.lookup("曲 & title", "Artist", "Album", 180.4, opener or self.open, **kwargs)

    def test_fetch_encoding_and_cache(self):
        self.assertEqual(self.fetch()["status"], "synced")
        query = parse_qs(urlsplit(self.calls[0].full_url).query)
        self.assertEqual(query["track_name"], ["曲 & title"])
        self.assertEqual(query["duration"], ["180"])
        self.assertEqual(self.fetch()["status"], "synced")
        self.assertEqual(len(self.calls), 1)

    def test_album_fallback_preserves_duration_matching(self):
        def fallback(request, timeout):
            if "album_name" in parse_qs(urlsplit(request.full_url).query):
                raise HTTPError(request.full_url, 404, "missing", {}, None)
            self.assertIn("duration=180", request.full_url)
            return self.open(request, timeout)
        self.assertEqual(self.fetch(fallback)["status"], "synced")
        self.assertNotIn("album_name", self.calls[0].full_url)

    def test_missing_is_cached_but_network_failure_can_retry(self):
        def offline(request, timeout):
            raise URLError("offline")
        self.assertEqual(self.fetch(offline)["status"], "offline")
        self.assertFalse(list(Path(self.tmp.name).rglob("*.json")))
        def missing(request, timeout):
            self.calls.append(request)
            raise HTTPError(request.full_url, 404, "missing", {}, None)
        self.assertEqual(self.fetch(missing)["status"], "missing")
        self.assertEqual(len(self.calls), 2)
        self.assertEqual(self.fetch()["status"], "missing")
        self.assertEqual(len(self.calls), 2)

    def test_instrumental_unsynced_and_invalid_responses(self):
        for record, expected in [({"instrumental": True}, "instrumental"),
                                 ({"plainLyrics": "Not timed"}, "unsynced"),
                                 ([], "offline")]:
            with self.subTest(record=record):
                for cache in Path(self.tmp.name).rglob("*.json"): cache.unlink()
                self.record = record
                self.assertEqual(self.fetch()["status"], expected)
        def malformed(request, timeout): return io.BytesIO(b"not JSON")
        self.assertEqual(self.fetch(malformed)["status"], "offline")

    def test_cache_expiry_corruption_rate_limit_and_empty_metadata(self):
        self.fetch()
        cache = next(Path(self.tmp.name).rglob("*.json"))
        with patch.object(lyrics.time, "time", return_value=1e12): self.fetch()
        self.assertEqual(len(self.calls), 2)
        cache.write_text("not JSON")
        self.fetch()
        self.assertEqual(len(self.calls), 3)
        cache.unlink()
        def limited(request, timeout): raise HTTPError(request.full_url, 429, "limit", {}, None)
        self.assertEqual(self.fetch(limited)["status"], "offline")
        self.assertFalse(cache.exists())
        self.assertEqual(lyrics.lookup("", "Artist", "", 0, self.open)["status"], "missing")
        self.assertEqual(len(self.calls), 3)


unittest.main()
