#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.14"
# dependencies = [
#   "rich",
# ]
# ///

import argparse
import json
import re
import subprocess
import sys
import time

from rich import print as rprint


def run_gh_command(args: list[str]) -> str:
    """Run a gh command and return the output."""
    result = subprocess.run(
        ["gh", *args],
        text=True,
        stdout=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise SystemExit(result.returncode)
    return result.stdout


def get_current_commit() -> str:
    """Get the current commit SHA."""
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        text=True,
        stdout=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise SystemExit(result.returncode)
    return result.stdout.strip()


def get_workflow_run(workflow_path: str, commit_sha: str) -> dict | None:
    """Get the workflow run for the given commit."""
    runs_json = run_gh_command(
        [
            "run",
            "list",
            "--commit",
            commit_sha,
            "--workflow",
            workflow_path,
            "--json",
            "databaseId,status,conclusion",
        ]
    )
    runs = json.loads(runs_json)

    if not runs:
        return None

    # Return the most recent run
    return runs[0]


def wait_for_completion(run_id: str, timeout: int = 1800) -> str:
    """Wait for the workflow run to complete. Returns the conclusion."""
    start_time = time.time()

    while True:
        if time.time() - start_time > timeout:
            raise TimeoutError(
                f"Workflow run did not complete within {timeout} seconds"
            )

        run_json = run_gh_command(
            ["run", "view", str(run_id), "--json", "status,conclusion"]
        )
        run = json.loads(run_json)

        status = run["status"]

        if status == "completed":
            return run["conclusion"]

        rprint(
            f"[dim]Waiting for workflow to complete... (status: {status})[/dim]",
            file=sys.stderr,
        )
        time.sleep(2)


def download_logs(run_id: str) -> str:
    """Download and return the logs for a workflow run."""
    logs = run_gh_command(["run", "view", str(run_id), "--log"])
    return logs


def extract_matches(logs: str, pattern: str) -> list[str]:
    """Extract all matches for the given regex pattern from logs."""
    regex = re.compile(pattern)
    matches = []

    for line in logs.split("\n"):
        for match in regex.finditer(line):
            matches.append(match.group(0))

    return matches


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Extract matching lines from GitHub Actions workflow logs"
    )
    parser.add_argument(
        "workflow",
        help="Path to the workflow file (e.g., .github/workflows/release.yml)",
    )
    parser.add_argument(
        "pattern",
        help="Regex pattern to search for in logs",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=1800,
        help="Timeout in seconds to wait for workflow completion (default: 1800)",
    )

    args = parser.parse_args(argv)

    try:
        commit_sha = get_current_commit()
        rprint(f"[dim]Current commit: {commit_sha}[/dim]", file=sys.stderr)

        # Get workflow run for this commit
        run = get_workflow_run(args.workflow, commit_sha)
        if not run:
            rprint(
                f"[dim]No workflow run found for commit {commit_sha} and workflow {args.workflow}[/dim]",
                file=sys.stderr,
            )
            return 1

        run_id = run["databaseId"]
        rprint(f"[dim]Found workflow run: {run_id}[/dim]", file=sys.stderr)

        # Wait for completion
        conclusion = wait_for_completion(run_id, args.timeout)
        rprint(
            f"[dim]Workflow completed with conclusion: {conclusion}[/dim]",
            file=sys.stderr,
        )

        # Download logs
        rprint("[dim]Downloading logs...[/dim]", file=sys.stderr)
        logs = download_logs(run_id)

        # Extract matches
        matches = extract_matches(logs, args.pattern)

        # Output results
        for match in matches:
            print(match)

        return 0

    except subprocess.CalledProcessError as e:
        rprint(f"[dim]Command failed: {e.cmd}[/dim]", file=sys.stderr)
        rprint(f"[dim]Error output: {e.stderr}[/dim]", file=sys.stderr)
        return 1
    except Exception as e:
        rprint(f"[dim]Error: {e}[/dim]", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
