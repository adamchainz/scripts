#!/usr/bin/env python
import datetime as dt
import gzip
import os
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import boto3

CACHE_DIR = Path("~/.cache/goaccess-cloudfront-logs").expanduser()

BUCKET = "adamj-eu-cloudfrontlogss3bucket-kufnb7l9dmho"
PREFIX = "E2KFDZF2ZTMT0H"
DAYS = 30


def main():
    today = dt.date.today()
    dates = [(today - dt.timedelta(days=n)).isoformat() for n in range(DAYS + 1)]
    dates.reverse()

    prefix_dir = CACHE_DIR / PREFIX
    prefix_dir.mkdir(parents=True, exist_ok=True)
    os.chdir(prefix_dir)

    print("Removing logs > 180 days old...")
    cutoff = today - dt.timedelta(days=180)
    for path in prefix_dir.glob(f"{PREFIX}.*"):
        date = path.parts[-1][len(PREFIX) + 1 :][:10]
        if dt.date.fromisoformat(date) < cutoff:
            print(path.parts[-1])
            path.unlink()

    print("Downloading logs...")
    s3 = boto3.resource("s3")
    bucket = s3.Bucket(BUCKET)

    def download_file(key, dest):
        if dest.exists():
            return
        print(key)
        s3.meta.client.download_file(
            BUCKET,
            key,
            str(dest),
        )

    with ThreadPoolExecutor() as executor:
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

    # Old slower download with 's3 sync'
    # subprocess.run(
    #     [
    #         "aws",
    #         "s3",
    #         "sync",
    #         f"s3://{BUCKET}",
    #         ".",
    #         "--exclude",
    #         "*",
    #         "--include",
    #         f"{PREFIX}.{glob_zip(*dates)}-*",
    #     ]
    # )

    print("Analyzing...")
    goaccess = subprocess.Popen(
        [
            "goaccess",
            "--log-format",
            "CLOUDFRONT",
            "--agent-list",
            "--no-query-string",
            "--ignore-crawlers",
            "--output",
            "index.html",
        ],
        stdin=subprocess.PIPE,
        # stderr=subprocess.DEVNULL,
    )
    for date in dates:
        for logfile in prefix_dir.glob(f"{PREFIX}.{date}*"):
            with gzip.open(logfile) as lfp:
                goaccess.stdin.write(lfp.read())

    print("Opening...")
    subprocess.run(["open", str((prefix_dir / "index.html").resolve())])


def glob_zip(*args):
    """
    Return a glob that matches any of the given inputs
    e.g. for (2020, 2021) output '202[01]'
    """
    out = ""
    char_sets = [set(items) for items in zip(*args)]
    for char_set in char_sets:
        if len(char_set) == 1:
            out += next(iter(char_set))
        else:
            out += "[" + "".join(sorted(char_set)) + "]"

    return out


if __name__ == "__main__":
    main()
