#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ ! -f pyproject.toml ]; then
    echo "pyproject.toml not found, not a Python project."
    exit 0
fi

if [ -f setup.py ]; then
    echo "setup.py exists, not migrating."
    exit 0
fi

if ! rg -q 'build-backend = "setuptools.build_meta"' pyproject.toml; then
    echo "Not using the setuptools build backend."
    exit 0
fi

if rg -q '\[tool\.setuptools' pyproject.toml; then
    echo "Has [tool.setuptools] configuration, not migrating."
    exit 0
fi

if [ ! -d src ]; then
    echo "No src layout, not migrating."
    exit 0
fi

# Swap the build-system table and, where the import name does not match the
# normalized project name, point uv_build at the module.

python3 << 'PYTHON'
import os
import re
import sys

with open("pyproject.toml") as f:
    text = f.read()

new_text = re.sub(
    r'build-backend = "setuptools\.build_meta"\nrequires = \[\n  "setuptools[^"]*",\n\]',
    'build-backend = "uv_build"\nrequires = [\n  "uv-build>=0.12.1,<0.13",\n]',
    text,
)
if new_text == text:
    sys.exit("Unrecognized build-system table, not migrating.")

name = re.search(r'^name = "([^"]+)"', new_text, flags=re.MULTILINE).group(1)
default_module = re.sub(r"[-._]+", "_", name).lower()
modules = [
    entry
    for entry in os.listdir("src")
    if os.path.isdir(os.path.join("src", entry)) and not entry.endswith(".egg-info")
]
if len(modules) != 1:
    sys.exit("Expected exactly one module in src/, not migrating.")
if modules[0] != default_module:
    new_text += f'\n[tool.uv.build-backend]\nmodule-name = "{modules[0]}"\n'

with open("pyproject.toml", "w") as f:
    f.write(new_text)
PYTHON

# pyproject-fmt folds any added [tool.uv.build-backend] table into [tool.uv]
prcr pyproject-fmt --files pyproject.toml || :

# MANIFEST.in is setuptools-specific. uv_build includes everything within the
# module directory in wheels, and the readme and license files per project
# metadata, covering the typical py.typed and package data includes.

if [ -f MANIFEST.in ]; then
    git rm --quiet MANIFEST.in
fi

# Check building works before committing

uv build
rm -rf dist

# Add changelog entry

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi

entry='* Switch package build backend from setuptools to `uv_build <https://docs.astral.sh/uv/concepts/build-backend/>`__.
  This makes builds with uv about nine times faster, since uv runs the backend natively, without creating a build environment or spawning a Python process.
  Additionally, source distributions no longer include test files, which setuptools previously included incompletely, missing the files needed to actually run them.'

python3 - "$changelog" "$entry" << 'PYTHON'
import sys

path, entry = sys.argv[1], sys.argv[2]

with open(path) as f:
    text = f.read()

unreleased = "Unreleased\n----------\n"
header = "=========\nChangelog\n=========\n"
if unreleased in text:
    text = text.replace(unreleased, f"{unreleased}\n{entry}\n", 1)
else:
    text = text.replace(header, f"{header}\n{entry}\n", 1)

with open(path, "w") as f:
    f.write(text)
PYTHON

# Commit

git switch -c uv_build_backend
git commit -a -n -m "Switch build backend to uv_build

setuptools works fine but the uv build backend is faster and requires less configuration, such as no MANIFEST.in file.

Docs: https://docs.astral.sh/uv/concepts/build-backend/"

# Final checks

pre-commit run -a || :

git push && gh pr create --fill && sleep 1 && gh pr merge --squash --delete-branch --auto
