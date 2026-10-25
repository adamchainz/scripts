#!/usr/bin/env uv run --script --no-project
# /// script
# requires-python = ">=3.14"
# ///
import argparse
import json
import subprocess


def gh(*args: str) -> str:
    return subprocess.run(
        ["gh", *args],
        capture_output=True,
        text=True,
        check=True,
    ).stdout


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Rerun failed workflow runs with cancelled jobs for a PR branch"
    )
    parser.add_argument("branch", help="PR branch name")
    args = parser.parse_args(argv)

    sha = gh(
        "pr",
        "view",
        args.branch,
        "--json",
        "headRefOid",
        "-q",
        ".headRefOid",
    ).strip()
    runs = json.loads(
        gh(
            "run",
            "list",
            "--commit",
            sha,
            "--json",
            "databaseId,conclusion,workflowName",
        )
    )

    rerun_any = False
    for run in runs:
        if run["conclusion"] != "failure":
            continue
        run_id = str(run["databaseId"])
        jobs = json.loads(gh("run", "view", run_id, "--json", "jobs"))["jobs"]
        cancelled = [j["name"] for j in jobs if j["conclusion"] == "cancelled"]
        if cancelled:
            print(
                f"Rerunning {run['workflowName']} ({run_id}), "
                + f"cancelled: {', '.join(cancelled)}"
            )
            subprocess.run(["gh", "run", "rerun", run_id, "--failed"], check=True)
            rerun_any = True

    if not rerun_any:
        print("No failed runs with cancelled jobs")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
