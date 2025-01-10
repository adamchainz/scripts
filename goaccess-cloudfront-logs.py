#!/usr/bin/env uv run
# /// script
# dependencies = [
#   "boto3",
# ]
# ///
from __future__ import annotations

import argparse
import datetime as dt
import gzip
import os
import subprocess
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import boto3

CACHE_DIR = Path("~/.cache/goaccess-cloudfront-logs").expanduser()

BUCKET = "adamj-eu-cloudfrontlogss3bucket-kufnb7l9dmho"
PREFIX = "E2KFDZF2ZTMT0H"


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=60)
    parser.add_argument("--dates", type=str, nargs="*")
    args = parser.parse_args(argv)
    days = args.days
    dates: list[str] = args.dates

    today = dt.date.today()
    if not args.dates:
        dates = [(today - dt.timedelta(days=n)).isoformat() for n in range(days)]
        dates.reverse()

    prefix_dir = CACHE_DIR / PREFIX
    prefix_dir.mkdir(parents=True, exist_ok=True)
    os.chdir(prefix_dir)

    print("Removing logs > 365 days old", end="", flush=True)
    cutoff = today - dt.timedelta(days=365)
    for path in prefix_dir.glob(f"{PREFIX}.*"):
        date = path.parts[-1][len(PREFIX) + 1 :][:10]
        if dt.date.fromisoformat(date) < cutoff:
            print(".", end="")
            path.unlink()
    print()

    print("Downloading logs", end="", flush=True)
    s3 = boto3.resource("s3")
    bucket = s3.Bucket(BUCKET)

    def download_file(key, dest):
        if dest.exists():
            return
        print(".", end="", flush=True)
        s3.meta.client.download_file(
            BUCKET,
            key,
            str(dest),
        )

    with ThreadPoolExecutor(max_workers=64) as executor:
        for date in dates:
            if date != today.isoformat():
                try:
                    next(prefix_dir.glob(f"{PREFIX}.{date}*"))
                except StopIteration:
                    already_have_files = False
                else:
                    already_have_files = True

                if already_have_files:
                    continue

            for obj in bucket.objects.filter(Prefix=f"{PREFIX}.{date}"):
                dest = prefix_dir / obj.key

                executor.submit(download_file, obj.key, dest)

    print("")

    print("Analyzing...")
    goaccess = subprocess.Popen(
        [
            "goaccess",
            "--log-format",
            "CLOUDFRONT",
            "--agent-list",
            "--no-query-string",
            "--http-protocol",
            "no",
            "--ignore-crawlers",
            "--static-file",
            ".xml",
            # bad IP’s
            "--exclude-ip",
            "45.88.3.145",
            "--exclude-ip",
            "5.183.213.186",
            "--exclude-ip",
            "14.32.74.251",
            "--exclude-ip",
            "118.189.194.123",
            "--exclude-ip",
            "2401:7400:6007:ba6a:68ad:8982:1d04:23a5",
            "--exclude-ip",
            "119.56.110.183",
            "--exclude-ip",
            "45.133.203.84",
            "--exclude-ip",
            "209.145.61.76",
            "--exclude-ip",
            "149.86.55.232",
            "--exclude-ip",
            "116.109.188.214",
            "--exclude-ip",
            "80.246.94.102",
            "--exclude-ip",
            "2001:6b0:d:738:c730:72f0:29bf:e38e",
            "--exclude-ip",
            "2001:6b0:d:738:682a:ac0f:6ae6:8826",
            "--exclude-ip",
            "2001:6b0:d:738:ee2e:bc8d:b6ac:1619",
            "--exclude-ip",
            "2001:6b0:d:738:942:509a:8aba:81f5",
            "--exclude-ip",
            "2001:f40:909:a91:6073:4de5:4b79:c6d1",
            "--exclude-ip",
            "2001:f40:909:a91:c85:9487:2592:3e46",
            "--exclude-ip",
            "2001:f40:909:a91:709c:5564:d9a1:f832",
            "--exclude-ip",
            "2001:f40:909:a91:2d0b:e449:a7b5:2624",
            "--exclude-ip",
            "2001:6b0:d:738:2fb1:e831:ac50:5c7",
            "--exclude-ip",
            "2001:f40:909:a91:6082:fd0b:8e7a:2cc8",
            "--exclude-ip",
            "2001:f40:909:a91:7886:9f61:5b86:403e",
            "--exclude-ip",
            "2001:f40:909:a91:b0bc:b458:dfa6:b190",
            "--exclude-ip",
            "2001:f40:909:a91:61e6:58ea:a9f7:6399",
            "--output",
            "index.html",
        ],
        stdin=subprocess.PIPE,
    )
    for date in dates:
        for logfile in prefix_dir.glob(f"{PREFIX}.{date}*"):
            with gzip.open(logfile) as lfp:
                goaccess.stdin.write(lfp.read())

    goaccess.stdin.close()
    goaccess.wait()

    subprocess.run(
        [
            "open",
            "-a",
            "Firefox",
            str((prefix_dir / "index.html").resolve()),
        ],
        check=True,
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
