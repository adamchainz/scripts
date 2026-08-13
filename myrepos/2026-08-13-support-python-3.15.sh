#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if rg -q -- "- '3.15'" .github/workflows/main.yml; then
    echo "Already supporting Python 3.15, nothing to add."
    exit 0
fi

# Add to CI test matrix

if rg -q -- "- '3.14t'" .github/workflows/main.yml; then
    sd --across -s \
"        - '3.14'
        - '3.14t'" \
"        - '3.14'
        - '3.14t'
        - '3.15'
        - '3.15t'" \
    .github/workflows/main.yml
else
    sd --across -s \
"        - '3.14'" \
"        - '3.14'
        - '3.15'" \
    .github/workflows/main.yml
fi

# Update declared supported versions

sd --across -s \
'  "Programming Language :: Python :: 3.14",' \
'  "Programming Language :: Python :: 3.14",
  "Programming Language :: Python :: 3.15",' \
pyproject.toml

sd -s \
'max_supported_python = "3.14"' \
'max_supported_python = "3.15"' \
pyproject.toml

uv lock

# Update tox grid

if [ -f tox.ini ]; then
    if rg -q -- '314t' tox.ini; then
        sd -s 'py{314, ' 'py{315, 314, ' tox.ini
        sd -s ', 314t' ', 315t, 314t' tox.ini
        # No Django projects use 314t, so no need to update that section.
    else
        # shellcheck disable=SC2016
        sd 'py\{314, (.*?)\}' 'py{315, 314, $1}' tox.ini
        sd -s \
'    py314-django{61, 60, 52}' \
'    py315-django{61}
    py314-django{61, 60, 52}' \
        tox.ini
    fi
fi

# Update documented supported versions

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
elif [ -f docs/index.rst ]; then
    installation=docs/index.rst
else
    installation=README.rst
fi
# shellcheck disable=SC2016
sd 'Python (.*?) to 3.14 supported.' 'Python $1 to 3.15 supported.' $installation

# # Add changelog entry

# if [ -f docs/changelog.rst ]; then
#     changelog=docs/changelog.rst
# else
#     changelog=CHANGELOG.rst
# fi

# entry="* Support Python 3.15."

# sd --across -f m '(=========
# Changelog
# =========

# Unreleased
# ----------)' "\$1

# $entry" "$changelog"

# if git diff --exit-code "$changelog" >/dev/null; then
#     sd --across -f m '(=========
# Changelog
# =========)' "\$1

# Unreleased
# ----------

# $entry" "$changelog"
# fi

# Commit

git switch -c python_3.15
git commit -a -n -m "Support Python 3.15"

# Final checks

tox run -f py315 || :

pre-commit run -a || :

echo "🔍 Check below search results for more to change..."
rg -C2 --pretty \
  --iglob '!.github/ISSUE_TEMPLATE/issue.yml' \
  --iglob '!.github/workflows/main.yml' \
  --iglob '!.pre-commit-config.yaml' \
  --iglob '!.readthedocs.yaml' \
  --iglob '!docs/changelog.rst' \
  --iglob '!docs/installation.rst' \
  --iglob '!CHANGELOG.rst' \
  --iglob '!pyproject.toml' \
  --iglob '!src/data.rs' \
  --iglob '!uv.lock' \
  --iglob '!*.svg' \
  --iglob '!*.css' \
  --iglob '!*.js' \
  '3\b.*\b(14|15)\b'

git status -sb
