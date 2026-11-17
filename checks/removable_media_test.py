import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("media", sys.argv.pop())
media = importlib.util.module_from_spec(spec)
spec.loader.exec_module(media)


class RemovableMediaTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.source = self.path / 'file "日本語".bin'; self.source.write_bytes(bytes(range(256))*100)
        self.dest = self.path / "destination.bin"; self.dest.write_bytes(self.source.read_bytes())
        self.mount = {"source": "/dev/sdb1", "target": "/run/media/hiroto/PS Vita", "fstype": "exfat"}
        self.calls = []

    def fake_run(self, command, **kwargs):
        self.calls.append(command)
        if command[0] == "findmnt":
            return subprocess.CompletedProcess(command, 0, json.dumps({"filesystems": [self.mount]}), "")
        return subprocess.CompletedProcess(command, 0)

    def test_matching_changed_and_missing_files(self):
        with contextlib.redirect_stdout(io.StringIO()):
            media.verify(self.source, self.dest)
            self.dest.write_bytes(b'corrupted')
            with self.assertRaisesRegex(ValueError, "不一致"): media.verify(self.source, self.dest)
            with self.assertRaises(ValueError): media.verify(self.source, self.path / "missing")

    def test_unmount_flushes_filesystem_before_nonforced_udisks_request(self):
        with patch.object(media.subprocess, "run", self.fake_run), contextlib.redirect_stdout(io.StringIO()):
            media.unmount("findmnt", "sync", "udisksctl", self.path)
        self.assertEqual(self.calls[1], ["sync", "-f", "--", "/run/media/hiroto/PS Vita"])
        self.assertEqual(self.calls[2], ["udisksctl", "unmount", "--block-device", "/dev/sdb1"])
        self.assertNotIn("--force", str(self.calls))
        self.assertNotIn("power-off", str(self.calls))

    def test_sync_failure_aborts_without_unmount(self):
        real_run = self.fake_run
        def fail_sync(command, **kwargs):
            if command[0] == "sync": raise subprocess.CalledProcessError(1, command)
            return real_run(command, **kwargs)
        with patch.object(media.subprocess, "run", fail_sync), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(subprocess.CalledProcessError): media.unmount("findmnt", "sync", "udisksctl", self.path)
        self.assertFalse(any(c[0] == "udisksctl" for c in self.calls))

    def test_busy_unmount_propagates_error_without_success_message(self):
        real_run = self.fake_run
        def busy(command, **kwargs):
            if command[0] == "udisksctl": raise subprocess.CalledProcessError(1, command)
            return real_run(command, **kwargs)
        output = io.StringIO()
        with patch.object(media.subprocess, "run", busy), contextlib.redirect_stdout(output):
            with self.assertRaises(subprocess.CalledProcessError): media.unmount("findmnt", "sync", "udisksctl", self.path)
        self.assertNotIn("完了しました", output.getvalue())

    def test_system_mounts_and_non_block_sources_are_refused(self):
        for target, source, fstype in [("/", "/dev/nvme0n1p2", "ext4"), ("/home", "/dev/sda1", "ext4"),
                                      ("/run/media", "/dev/sdb1", "exfat"), ("/mediax/Vita", "/dev/sdb1", "exfat"),
                                      ("/media/Vita", "tmpfs", "tmpfs"), ("/media/Vita", "/dev/sdb1[/subdir]", "ext4")]:
            with self.subTest(target=target, source=source):
                self.mount.update(target=target, source=source, fstype=fstype)
                with patch.object(media.subprocess, "run", self.fake_run):
                    with self.assertRaises(ValueError): media.removable_mount("findmnt", self.path)
        self.assertTrue(all(c[0] == "findmnt" for c in self.calls))


unittest.main()
