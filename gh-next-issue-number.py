#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.14"
# ///
import json
import subprocess
from typing import Any


def main() -> int:
    try:
        next_number = get_next_number()
        print(next_number)
    except subprocess.CalledProcessError:
        return 1

    return 0


def run_gh(args: list[str]) -> dict[str, Any]:
    result = subprocess.run(
        ["gh", *args],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def get_next_number() -> int:
    result = run_gh(
        [
            "api",
            "-X",
            "GET",
            "search/issues",
            "-F",
            "q=repo:{owner}/{repo}",
            "-F",
            "sort=created",
            "-F",
            "order=desc",
            "-F",
            "per_page=1",
        ]
    )

    return (result["items"][0]["number"] if result["items"] else 0) + 1


if __name__ == "__main__":
    raise SystemExit(main())
