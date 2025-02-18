#!/usr/bin/env uv run
# /// script
# requires-python = ">=3.13"
# ///
import json
import subprocess


def main(argv=None) -> int:
    query = """
    query {
        search(query: "is:pr is:merged author:@me sort:updated-desc", type: ISSUE, first: 100) {
            nodes {
            ... on PullRequest {
                headRefName
                headRepository { nameWithOwner }
            }
            }
        }
    }
    """
    pr_data = subprocess.run(
        ["gh", "api", "graphql", "-f", f"query={query}"],
        capture_output=True,
        text=True,
        check=True,
    )

    data = json.loads(pr_data.stdout)
    for pr in data["data"]["search"]["nodes"]:
        repo = pr["headRepository"]["nameWithOwner"]
        branch = pr["headRefName"]

        check_exists = subprocess.run(
            ["gh", "api", f"repos/{repo}/branches/{branch}"],
            capture_output=True,
        )
        if check_exists.returncode == 0:
            print(f"Deleting {repo}: {branch}")
            subprocess.run(
                ["gh", "api", "-X", "DELETE", f"repos/{repo}/git/refs/heads/{branch}"],
                check=True,
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
