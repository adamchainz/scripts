#!/usr/bin/env uv run
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "packaging",
# ]
# ///
import argparse
import datetime as dt
import json
import os
import subprocess
import sys
import tomllib
from functools import partial
from glob import glob
from pathlib import Path
from textwrap import dedent

from packaging.version import Version

run = partial(subprocess.run, check=True)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Perform a release for the current Python package."
    )
    parser.add_argument("change", choices=["major", "minor", "patch"])
    parser.add_argument("--sdist-only", action="store_true")
    parser.add_argument("--skip-changelog", action="store_true")
    args = parser.parse_args(argv)
    change = args.change
    sdist_only = args.sdist_only
    skip_changelog = args.skip_changelog

    run(["git", "diff", "--exit-code"])
    main_exists = (
        subprocess.run(
            ["git", "rev-parse", "--quiet", "--verify", "main"],
            capture_output=True,
        ).returncode
        == 0
    )
    if main_exists:
        default_branch = "main"
    else:
        default_branch = "master"
    run(["git", "switch", default_branch])
    run(["git", "pull"])

    # check that we are in the root of the repository
    proc = run(
        ["git", "rev-parse", "--path-format=relative", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if proc.stdout.strip() != "./":
        print("❌ Not in the root of the repository", file=sys.stderr)
        return 1

    # check for unpushed commits
    proc = run(
        ["git", "rev-list", "HEAD...@{u}", "--count"], capture_output=True, text=True
    )
    if proc.stdout.strip() != "0":
        print("❌ Unpushed commits", file=sys.stderr)
        return 1

    proc = run(["git", "tag", "--contains", "HEAD"], capture_output=True, text=True)
    tag = proc.stdout.strip()
    if tag != "":
        print(
            f"❌ Current commit already tagged {tag!r}",
            file=sys.stderr,
        )
        return 1

    with Path("pyproject.toml").open("rb") as fp:
        current_version = Version(tomllib.load(fp)["project"]["version"])

    if change == "major":
        version = f"{current_version.major + 1}.0.0"
    elif change == "minor":
        version = f"{current_version.major}.{current_version.minor + 1}.0"
    else:
        assert change == "patch"
        version = f"{current_version.major}.{current_version.minor}.{current_version.micro + 1}"

    # Check GitHub Actions are all successful for the current commit
    # May be replaceable in future with gh cli builtin:
    # https://github.com/cli/cli/issues/1055
    latest_commit = run(
        ["git", "rev-parse", "HEAD"], capture_output=True, text=True
    ).stdout.strip()
    status_query = dedent(
        """\
        query ($owner: String!, $name: String!, $commit: String!) {
          repository(owner: $owner, name: $name) {
            object(expression: $commit) {
              ... on Commit {
                checkSuites(first: 100) {
                  nodes {
                    creator {
                      name
                    }
                    resourcePath
                    status
                    app {
                      name
                    }
                    conclusion
                    checkRuns(first: 10) {
                      nodes {
                        conclusion
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        }
        """
    )
    checks_data = json.loads(
        run(
            [
                "gh",
                "api",
                "graphql",
                "-F",
                r"owner={owner}",
                "-F",
                r"name={repo}",
                "-F",
                f"commit={latest_commit}",
                "-f",
                f"query={status_query}",
            ],
            capture_output=True,
            text=True,
        ).stdout
    )
    check_suites = checks_data["data"]["repository"]["object"]["checkSuites"]["nodes"]
    check_suites = [
        s
        for s in check_suites
        if (
            # Ignored apps: Travis CI and AppVeyor show up in pytest org where
            # other repos use them, but I don't.
            s["app"] is not None
            and s["app"]["name"] not in ("Travis CI", "AppVeyor")
        )
        and not (
            # Dependabot allowed to fail, sometimes it’s broken, and all it
            # does is make PRs
            s["app"] is not None
            and s["app"]["name"] == "GitHub Actions"
            and len(s["checkRuns"]["nodes"]) == 1
            and s["checkRuns"]["nodes"][0]["name"] == "Dependabot"
        )
    ]
    if not all(s["conclusion"] == "SUCCESS" for s in check_suites):
        print("❌ Not all checks are successful:", file=sys.stderr)
        for check_suite in check_suites:
            for check_run in check_suite["checkRuns"]["nodes"]:
                print(
                    f"    {check_run['name']}: {check_run['conclusion']}",
                    file=sys.stderr,
                )
        return 1

    run(
        ["sd", '^version = ".*"$', f'version = "{version}"', "pyproject.toml"],
    )
    if Path("uv.lock").exists():
        run(["uv", "lock"])
    if Path("Cargo.toml").exists():
        run(
            ["sd", '^version = ".*"$', f'version = "{version}"', "Cargo.toml"],
        )
        run(["cargo", "check"])

    if not skip_changelog:
        changelog_path = Path("docs/changelog.rst")
        if not changelog_path.exists():
            changelog_path = Path("CHANGELOG.rst")

        changelog_contents = changelog_path.read_text()
        changelog_lines = changelog_contents.splitlines()
        assert changelog_lines[0] == "========="
        assert changelog_lines[1] == "Changelog"
        assert changelog_lines[2] == "========="
        assert changelog_lines[3] == ""
        if changelog_lines[4] == "Unreleased":
            assert changelog_lines[5] == "----------"
            assert changelog_lines[6] == ""
            del changelog_lines[4:7]

        assert changelog_lines[4].startswith("* ")

        today = dt.date.today().isoformat()
        version_line = f"{version} ({today})"
        underline = "-" * len(version_line)
        changelog_lines.insert(4, "")
        changelog_lines.insert(4, underline)
        changelog_lines.insert(4, version_line)

        changelog_path.write_text("\n".join(changelog_lines) + "\n")

    files_to_add = ["pyproject.toml"]
    if not skip_changelog:
        files_to_add.append(changelog_path)
    if Path("uv.lock").exists():
        files_to_add.append("uv.lock")
    if Path("Cargo.toml").exists():
        files_to_add.extend(["Cargo.toml", "Cargo.lock"])
    run(["git", "add", *files_to_add])
    run(["git", "commit", "--message", f"Version {version}"])

    if "release:" not in Path(".github/workflows/main.yml").read_text():
        # Local build
        run(["rm", "-rf", "build", "dist", *glob("src/*.egg-info")])

        build_command = ["pyproject-build", "--installer", "uv"]
        if sdist_only:
            build_command.append("--sdist")
        run(build_command, env={**os.environ, "PIP_REQUIRE_VIRTUALENV": "0"})

        run(["twine", "check", *glob("dist/*")])
        run(["twine", "upload", *glob("dist/*")])

    run(["git", "push", "origin", default_branch])
    run(["git", "tag", "--annotate", version, "--message", f"Version {version}"])
    run(["git", "push", "--tags", "origin", version])


if __name__ == "__main__":
    raise SystemExit(main())
