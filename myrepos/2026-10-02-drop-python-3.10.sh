#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if ! rg -q -F 'requires-python = ">=3.10"' pyproject.toml; then
    echo "Skipping project since it doesn't support Python 3.10."
    exit 0
fi

# Remove from CI test matrix

if rg -q -- "- '3.10'" .github/workflows/main.yml; then
    has_ci_job=1
else
    has_ci_job=0
fi
sd --across $' +- \'3\\.10\'\n' '' .github/workflows/main.yml

# Update declared supported versions

sd -s 'requires-python = ">=3.10"' 'requires-python = ">=3.11"' pyproject.toml
sd --across '  "Programming Language :: Python :: 3.10",\n' '' pyproject.toml
sd --across '  "cp310-\*",\n' '' pyproject.toml
# Markers that are now always true
sd -s "; python_version>='3.10'\"" '"' pyproject.toml

uv lock

# Update tox grid

if [ -f tox.ini ]; then
    sd --across ' +py310\b.*\n' '' tox.ini
    # shellcheck disable=SC2016
    sd '(py\{[^}]*), 310\b' '$1' tox.ini
fi

# Update documented supported versions

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
elif [ -f docs/index.rst ]; then
    installation=docs/index.rst
else
    installation=README.rst
fi
sd -s 'Python 3.10 to ' 'Python 3.11 to ' $installation

# Add changelog entry

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi

entry="* Drop Python 3.10 support."

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

git switch -c drop_python_3.10
git commit -a -n -m "Drop Python 3.10 support

It reaches EOL this month: https://peps.python.org/pep-0619/#lifespan."

if [ $has_ci_job = 1 ]; then
    gh-branch-protection-checks.py remove main 'Python 3.10'
fi

# Final checks

pre-commit run -a || :

echo "🔍 Check below search results for more to change..."
rg -C2 --pretty \
  --iglob '!docs/changelog.rst' \
  --iglob '!CHANGELOG.rst' \
  --iglob '!HISTORY.rst' \
  --iglob '!uv.lock' \
  --iglob '!*.svg' \
  --iglob '!*.css' \
  --iglob '!*.js' \
  '3\b.*\b(10|11)\b|0x030[aAbB]' || :

git status -sb
