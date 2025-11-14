#!/usr/bin/env uv run --script
# # /// script
# requires-python = ">=3.14"
# dependencies = [
#     "urllib3",
# ]
# ///
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from pathlib import Path

import urllib3


def get_sdist_url(package_name: str, version: str) -> str:
    """Get the sdist URL from PyPI JSON API."""
    http = urllib3.PoolManager()
    url = f"https://pypi.org/pypi/{package_name}/{version}/json"

    print(f"Fetching metadata for {package_name}=={version}...", file=sys.stderr)
    response = http.request("GET", url)

    if response.status != 200:
        raise RuntimeError(f"Failed to fetch package metadata: HTTP {response.status}")

    data = json.loads(response.data.decode("utf-8"))

    # Find the sdist URL
    for url_info in data["urls"]:
        if url_info["packagetype"] == "sdist":
            return url_info["url"]

    raise RuntimeError(f"No sdist found for {package_name}=={version}")


def download_file(url: str, target_path: Path) -> None:
    """Download a file from a URL."""
    http = urllib3.PoolManager()
    print(f"Downloading {url}...", file=sys.stderr)

    response = http.request("GET", url)
    if response.status != 200:
        raise RuntimeError(f"Failed to download file: HTTP {response.status}")

    target_path.write_bytes(response.data)


def extract_package(archive_path: Path, extract_dir: Path) -> Path:
    """Extract a package archive and return the path to the extracted directory."""
    print(f"Extracting {archive_path.name}...", file=sys.stderr)
    subprocess.run(
        ["tar", "-xzf", str(archive_path), "-C", str(extract_dir)],
        check=True,
    )
    # Find the extracted directory (usually package-name-version)
    extracted = [d for d in extract_dir.iterdir() if d.is_dir()]
    if not extracted:
        raise RuntimeError(f"No directory found after extracting {archive_path}")
    return extracted[0]


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Diff two versions of a Python package from their sdist archives on PyPI. "
            "Useful when a package doesn't have any public code repository or changelog, "
            "like red-black-tree-mod."
        )
    )
    parser.add_argument("package", help="Package name")
    parser.add_argument("version1", help="First version")
    parser.add_argument("version2", help="Second version")
    args = parser.parse_args(argv)

    with tempfile.TemporaryDirectory() as tmpdir:
        tmppath = Path(tmpdir)

        dirs = []
        for version in (args.version1, args.version2):
            url = get_sdist_url(args.package, version)
            archive = tmppath / f"{args.package}-{version}.tar.gz"
            download_file(url, archive)
            extracted_dir = extract_package(archive, tmppath)
            dirs.append(extracted_dir)

        dir1, dir2 = dirs

        print(f"\nDiff between {args.version1} and {args.version2}:\n", file=sys.stderr)
        subprocess.run(
            ["git", "diff", "--no-index", str(dir1), str(dir2)],
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
