#!/usr/bin/env python
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

    print("Removing logs > 180 days old", end="", flush=True)
    cutoff = today - dt.timedelta(days=180)
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

    with ThreadPoolExecutor(max_workers=16) as executor:
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

    subprocess.run(["open", str((prefix_dir / "index.html").resolve())], check=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
