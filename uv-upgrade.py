#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.14"
# ///
import argparse
import subprocess
import sys


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


def upgrade_packages(packages: set[str]) -> None:
    """Run uv lock with -P flags for each package."""
    if not packages:
        print("No packages found to upgrade.", file=sys.stderr)
        return

    cmd = ["uv", "lock"]
    for package in sorted(packages):
        cmd.extend(["-P", package])

    print(f"Upgrading {len(packages)} package(s): {', '.join(sorted(packages))}")
    subprocess.run(cmd, check=True)


def main():
    parser = argparse.ArgumentParser(
        description="Upgrade a package and all its transitive dependencies"
    )
    parser.add_argument(
        "--package-tree",
        required=True,
        help="Package name to upgrade with all its dependencies",
    )
    args = parser.parse_args()

    tree_output = get_dependency_tree()
    packages = parse_tree(tree_output, args.package_tree)
    upgrade_packages(packages)


if __name__ == "__main__":
    main()
