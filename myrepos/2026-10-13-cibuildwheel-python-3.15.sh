#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if ! rg -q -F '[tool.cibuildwheel]' pyproject.toml; then
    echo "Skipping project since it doesn't use cibuildwheel."
    exit 0
fi

if ! rg -q -F '"Programming Language :: Python :: 3.15",' pyproject.toml; then
    echo "Skipping project since it doesn't support Python 3.15 yet."
    exit 0
fi

if rg -q -F '"cp315-*",' pyproject.toml; then
    echo "Skipping project since it already builds Python 3.15 wheels."
    exit 0
fi

# Upgrade cibuildwheel to the first version building the final 3.15.0 release

sd '"cibuildwheel>=[0-9.]+",' '"cibuildwheel>=4.3.1",' pyproject.toml

# Add to cibuildwheel build list

if rg -q -F '"cp314t-*",' pyproject.toml; then
    sd --across -s \
'  "cp314-*",' \
'  "cp315-*",
  "cp315t-*",
  "cp314-*",' \
    pyproject.toml
else
    sd --across -s \
'  "cp314-*",' \
'  "cp315-*",
  "cp314-*",' \
    pyproject.toml
fi

uv lock --upgrade-package cibuildwheel

# Add changelog entry

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi

entry="* Publish wheels for Python 3.15."

sd --across -f m '(=========
Changelog
=========

(Unreleased|Pending)
-+)' "\$1

$entry" "$changelog"

# Projects with unreleased entries directly under the title
if git diff --exit-code "$changelog" >/dev/null; then
    sd --across -f m '(=========
Changelog
=========

)\*' "\${1}$entry

*" "$changelog"
fi

if git diff --exit-code "$changelog" >/dev/null; then
    sd --across -f m '(=========
Changelog
=========)' "\$1

Unreleased
----------

$entry" "$changelog"
fi

# Commit

git switch -c python_3.15_wheels
git commit -a -n -m "Publish wheels for Python 3.15

cibuildwheel 4.3.1 builds with the final 3.15.0 release: https://cibuildwheel.pypa.io/en/stable/changelog/."

# Final checks

pre-commit run -a || :

echo "🔍 Check below build identifiers include Python 3.15..."
uv run --only-group build cibuildwheel --print-build-identifiers --platform linux --archs x86_64

echo "🛞 Add the 'Build' label to the PR to build wheels on CI."

git status -sb
