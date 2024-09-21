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
    parser.add_argument("version")
    parser.add_argument("--sdist-only", action="store_true")
    parser.add_argument("--skip-changelog", action="store_true")
    args = parser.parse_args(argv)
    version = args.version
    sdist_only = args.sdist_only
    skip_changelog = args.skip_changelog

    if os.environ.get("VIRTUAL_ENV"):
        print(
            "❌ Use system Python not a virtual environment",
            file=sys.stderr,
        )
        return 1

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
    run(["git", "checkout", default_branch])
    run(["git", "pull"])

    proc = run(["git", "tag", "--contains", "HEAD"], capture_output=True)
    tag = proc.stdout.decode().strip()
    if tag != "":
        print(
            f"❌ Current commit already tagged {tag!r}",
            file=sys.stderr,
        )
        return 1

    with Path("pyproject.toml").open("rb") as fp:
        current_version = Version(tomllib.load(fp)["project"]["version"])

    if version == "major":
        version = f"{current_version.major + 1}.0.0"
    elif version == "minor":
        version = f"{current_version.major}.{current_version.minor + 1}.0"
    elif version == "patch":
        version = f"{current_version.major}.{current_version.minor}.{current_version.micro + 1}"

    if Version(version) <= current_version:
        print(
            f"❌ Given version {version} < current version {current_version}",
            file=sys.stderr,
        )
        return 1

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
            s["app"] is not None
            # Ignored apps: I don't use Dependabot, and Travis CI and AppVeyor
            # show up in pytest org where other repos use them, but I don't
            and s["app"]["name"] not in ("Dependabot", "Travis CI", "AppVeyor")
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
        ["sd", 'version = ".*"', f'version = "{version}"', "pyproject.toml"],
    )

    if not skip_changelog:
        today = dt.date.today().isoformat()
        version_line = f"{version} ({today})"
        underline = "-" * len(version_line)

        if os.path.exists("docs/changelog.rst"):
            changelog_path = "docs/changelog.rst"
        else:
            changelog_path = "CHANGELOG.rst"

        run(
            [
                "sd",
                "--flags",
                "m",
                "(=========\nChangelog\n=========)",
                f"$1\n\n{version_line}\n{underline}",
                changelog_path,
            ],
        )

    files_to_add = ["pyproject.toml"]
    if not skip_changelog:
        files_to_add.append(changelog_path)
    run(["git", "add", *files_to_add])
    run(["git", "commit", "--message", f"Version {version}"])

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
