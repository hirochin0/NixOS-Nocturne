"""Flush/unmount a user-mounted removable volume; compare transferred files."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def verify(source, destination):
    if not source.is_file() or not destination.is_file():
        raise ValueError("比較する2つのファイルを指定してください")
    first, second = digest(source), digest(destination)
    print(f"元ファイル: {first}  {source}")
    print(f"転送先:     {second}  {destination}")
    if first != second:
        raise ValueError("不一致です。転送先を使わず、元ファイルを保持して原因を確認してください")
    print("SHA-256が一致しました")


def removable_mount(findmnt, path):
    path = path.expanduser().resolve(strict=True)
    result = subprocess.run([findmnt, "--json", "--target", str(path), "--output", "SOURCE,TARGET,FSTYPE"],
                            check=True, capture_output=True, text=True, timeout=10)
    entries = json.loads(result.stdout).get("filesystems", [])
    if len(entries) != 1:
        raise ValueError("マウント先を特定できませんでした")
    mount = entries[0]
    target = Path(mount["target"]).resolve()
    if not any(target.is_relative_to(base) and target != base for base in (Path("/run/media"), Path("/media"))):
        raise ValueError("/run/media または /media 配下のマウント先を指定してください。システム領域は操作しません")
    source = mount["source"]
    if not source.startswith("/dev/") or '[' in source or mount["fstype"] in ("autofs", "tmpfs", "overlay"):
        raise ValueError("USBなどのブロックデバイスのマウント先を指定してください")
    return source, target


def unmount(findmnt, sync, udisksctl, path):
    source, target = removable_mount(findmnt, path)
    print(f"{target} の書き込み完了を待っています…", flush=True)
    subprocess.run([sync, "-f", "--", str(target)], check=True)
    # No force, lazy unmount or power-off: a busy filesystem must report failure.
    subprocess.run([udisksctl, "unmount", "--block-device", source], check=True)
    print("アンマウントが完了しました。VitaShellのUSB接続を終了してからケーブルを抜いてください")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--findmnt", required=True)
    parser.add_argument("--sync", required=True)
    parser.add_argument("--udisksctl", required=True)
    commands = parser.add_subparsers(dest="command", required=True)
    eject = commands.add_parser("unmount", help="書き込み完了を待ってからアンマウント")
    eject.add_argument("path", type=Path)
    compare = commands.add_parser("verify", help="元ファイルと転送先のSHA-256を比較")
    compare.add_argument("source", type=Path)
    compare.add_argument("destination", type=Path)
    args = parser.parse_args()
    if args.command == "unmount": unmount(args.findmnt, args.sync, args.udisksctl, args.path)
    else: verify(args.source.expanduser(), args.destination.expanduser())


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"nocturne-usb: {error}", file=sys.stderr)
        sys.exit(1)
