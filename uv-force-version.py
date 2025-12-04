#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "tomlkit",
# ]
# ///
import argparse
import subprocess
from pathlib import Path

import tomlkit


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Force a specific version of a package in pyproject.toml and uv.lock. "
            "The package must be specified with == in pyproject.toml dependencies."
        )
    )
    parser.add_argument(
        "package",
        help="The name of the package to update.",
    )
    parser.add_argument(
        "version",
        help="The version to set for the package.",
    )

    args = parser.parse_args()
    package = args.package
    version = args.version

    pyproject = Path("pyproject.toml")
    pyproject_data = tomlkit.parse(pyproject.read_text())
    dependencies = pyproject_data["project"]["dependencies"]
    index = next(
        i for i, dep in enumerate(dependencies) if dep.startswith(f"{package}==")
    )
    dependencies[index] = f"{package}=={version}"
    if "dev" in version:
        override_dependencies = pyproject_data["tool"]["uv"]["override-dependencies"]
        index = next(
            (
                i
                for i, dep in enumerate(override_dependencies)
                if dep.startswith(f"{package}==")
            ),
            None,
        )
        if index is None:
            override_dependencies.append(f"{package}=={version}")
        else:
            override_dependencies[index] = f"{package}=={version}"
    pyproject.write_text(tomlkit.dumps(pyproject_data))

    subprocess.run(["uv", "lock"])

    uv_lock = Path("uv.lock")
    uv_lock_data = tomlkit.parse(uv_lock.read_text())
    uv_lock_data["revision"] = 2
    uv_lock.write_text(tomlkit.dumps(uv_lock_data))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
