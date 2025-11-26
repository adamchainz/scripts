#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.14"
# ///
import argparse
import subprocess
import sys
from pathlib import Path

import tomllib


def get_dependency_tree() -> str:
    """Run uv tree --no-dedupe and return the output."""
    result = subprocess.run(
        ["uv", "tree", "--all-groups", "--no-dedupe"],
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(result.returncode)
    return result.stdout


def get_inverted_dependency_tree(package: str) -> str:
    """Run uv tree --invert for a specific package and return the output."""
    result = subprocess.run(
        ["uv", "tree", "--all-groups", "--no-dedupe", "--invert", "--package", package],
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(result.returncode)
    return result.stdout


def get_project_name() -> str:
    """Parse the project name from pyproject.toml."""
    pyproject_path = Path("pyproject.toml")
    if not pyproject_path.exists():
        print(
            "Warning: pyproject.toml not found, cannot determine project name",
            file=sys.stderr,
        )
        return ""

    with open(pyproject_path, "rb") as f:
        data = tomllib.load(f)

    return data.get("project", {}).get("name", "")


def parse_tree(tree_output: str, target_package: str) -> set[str]:
    """Parse the tree output and extract all dependencies of the target package."""
    lines = tree_output.strip().split("\n")
    packages = set()
    in_target_subtree = False
    target_depth = 0

    for line in lines:
        # Skip non-package lines
        if not line.strip() or "Resolved" in line:
            continue

        # Calculate depth by counting tree characters before the package name
        # Count sequences of "│   " (continuing branch) and final "├── " or "└── "
        depth = 0
        temp_line = line

        # Count vertical bars (│) which indicate depth
        while "│" in temp_line or "├" in temp_line or "└" in temp_line:
            if temp_line.lstrip().startswith("├") or temp_line.lstrip().startswith("└"):
                # This is the final connector before the package name
                break
            # Count this level and remove it
            if "│" in temp_line:
                depth += 1
                # Remove up to and including the first │ and following spaces
                idx = temp_line.index("│")
                temp_line = temp_line[idx + 1 :].lstrip(" ")
            else:
                break

        # Extract package name
        stripped = line.lstrip("│├└─ ")
        parts = stripped.split()
        if len(parts) < 2:
            continue

        package_name = parts[0]

        # Check if this is our target package
        if package_name == target_package and not in_target_subtree:
            packages.add(package_name)
            in_target_subtree = True
            target_depth = depth
            continue

        # If we're in the target subtree, collect dependencies
        if in_target_subtree:
            # If depth is less than or equal to target, we've exited the subtree
            if depth <= target_depth:
                in_target_subtree = False
                continue

            # This is a dependency of the target package
            packages.add(package_name)

    return packages


def parse_inverted_tree(tree_output: str, project_name: str) -> set[str]:
    """Parse the inverted tree output and extract all packages that depend on the target package.

    Skips the project package itself.
    """
    lines = tree_output.strip().split("\n")
    packages = set()

    for line in lines:
        # Skip non-package lines
        if not line.strip() or "Resolved" in line:
            continue

        # Extract package name (before the version)
        stripped = line.lstrip("│├└─ ")
        parts = stripped.split()
        if len(parts) < 2:
            continue

        package_name = parts[0]

        # Remove extras from package name (e.g., "maroon-bells[argon2]" -> "maroon-bells")
        package_name_base = package_name.split("[")[0]

        # Skip the project package itself
        if project_name and package_name_base == project_name:
            continue

        packages.add(package_name)

    return packages


def upgrade_packages(packages: set[str], dry_run: bool = False) -> None:
    """Run uv lock with -P flags for each package, or print the command if dry_run is True."""
    if not packages:
        print("No packages found to upgrade.", file=sys.stderr)
        return

    cmd = ["uv", "lock"]
    for package in sorted(packages):
        cmd.extend(["-P", package])

    print(f"Upgrading {len(packages)} package(s): {', '.join(sorted(packages))}")

    if dry_run:
        print("\nDry run - would execute:")
        print(" ".join(cmd))
    else:
        subprocess.run(cmd, check=True)


def main():
    parser = argparse.ArgumentParser(
        description="Upgrade a package and all its transitive dependencies or dependents."
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--package-tree",
        help="Package name to upgrade with all its dependencies.",
    )
    group.add_argument(
        "--package-dependents",
        help="Package name to upgrade with all packages that depend on it.",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the command that would be run without executing it",
    )

    args = parser.parse_args()

    if args.package_tree:
        tree_output = get_dependency_tree()
        packages = parse_tree(tree_output, args.package_tree)
    else:  # args.package_dependents
        project_name = get_project_name()
        tree_output = get_inverted_dependency_tree(args.package_dependents)
        packages = parse_inverted_tree(tree_output, project_name)

    upgrade_packages(packages, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
