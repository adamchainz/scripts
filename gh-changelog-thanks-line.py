#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.13"
# ///
import json
import subprocess
from typing import Any


def main() -> int:
    try:
        owner, repo = get_repo_info()
        pr_number, author_name = get_pr_info()
    except subprocess.CalledProcessError:
        return 1

    repo_url = f"https://github.com/{owner}/{repo}"

    print(
        f"Thanks to {author_name} in `PR #{pr_number} <{repo_url}/pull/{pr_number}>`__."
    )
    return 0


def run_gh(args: list[str]) -> dict[str, Any]:
    result = subprocess.run(
        ["gh", *args],
        stdout=subprocess.PIPE,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def get_repo_info() -> tuple[str, str]:
    info = run_gh(["repo", "view", "--json", "owner,name"])
    return info["owner"]["login"], info["name"]


def get_pr_info() -> tuple[int, str]:
    info = run_gh(["pr", "view", "--json", "number,author"])
    author = info["author"]
    author_name = author["name"] if author["name"] else author["login"]
    return info["number"], author_name


if __name__ == "__main__":
    raise SystemExit(main())
