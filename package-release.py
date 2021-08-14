#!/usr/bin/env python
import argparse
import datetime as dt
import os
import subprocess
import sys
from configparser import ConfigParser
from functools import partial
from glob import glob

from packaging.version import Version

run = partial(subprocess.run, check=True)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Perform a release for the current Python package."
    )
    parser.add_argument("version")
    parser.add_argument("--sdist-only", action="store_true")
    args = parser.parse_args(argv)
    version = args.version
    sdist_only = args.sdist_only

    if os.environ.get("VIRTUAL_ENV"):
        print(
            "❌ Use system Python not a virtual environment",
            file=sys.stderr,
        )
        return 1

    run(["git", "diff", "--exit-code"])
    run(["git", "checkout", "main"])
    run(["git", "pull"])

    config_parser = ConfigParser()
    config_parser.read(["setup.cfg"])
    current_version = Version(config_parser.get("metadata", "version"))
    if Version(version) <= current_version:
        print(
            f"❌ Given version {version} < current version {current_version}",
            file=sys.stderr,
        )
        return 1

    run(
        ["sd", "version = .*", f"version = {version}", "setup.cfg"],
    )

    today = dt.date.today().isoformat()
    version_line = f"{version} ({today})"
    underline = "-" * len(version_line)

    run(
        [
            "sd",
            "--flags",
            "m",
            "(=======\nHistory\n=======)",
            f"$1\n\n{version_line}\n{underline}",
            "HISTORY.rst",
        ],
    )

    run(["git", "add", "setup.cfg", "HISTORY.rst"])
    run(["git", "commit", "--message", f"Version {version}"])

    run(["rm", "-rf", "build", "dist", *glob("src/*.egg-info")])

    if sdist_only:
        run(["python", "setup.py", "clean", "sdist"])
    else:
        run(["python", "-m", "build"], env={**os.environ, "PIP_REQUIRE_VIRTUALENV": ""})

    run(["twine", "check", *glob("dist/*")])
    run(["twine", "upload", *glob("dist/*")])

    run(["git", "push", "origin", "main"])
    run(["git", "tag", version])
    run(["git", "push", "--tags", "origin", version])


if __name__ == "__main__":
    exit(main())
