#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if rg -q -- "- '3.14'" .github/workflows/main.yml; then
  echo "Skipping project since it already supports Python 3.14."
  exit
fi

sd -s \
"        - '3.13'" \
"        - '3.13'
        - '3.14'" \
.github/workflows/main.yml


sd -s \
'  "Programming Language :: Python :: 3.13",' \
'  "Programming Language :: Python :: 3.13",
  "Programming Language :: Python :: 3.14",' \
pyproject.toml

sd -s \
'max_supported_python = "3.13"' \
'max_supported_python = "3.14"' \
pyproject.toml

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi
sd -f m '(=========
Changelog
=========)' "\$1

Unreleased
----------

* Support Python 3.14." $changelog

# shellcheck disable=SC2016
sd 'Python (.*?) to 3.13 supported.' 'Python $1 to 3.14 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Python (.*?) to 3.13 supported.' 'Python $1 to 3.14 supported.' docs/installation.rst
  git add docs/installation.rst
fi


uv lock

git add .github/workflows/main.yml .pre-commit-config.yaml pyproject.toml $changelog README.rst uv.lock

# if tox.ini exists
if [ -f tox.ini ]; then
  # shellcheck disable=SC2016
  sd 'py\{313, (.*?)\}' 'py{314, 313, $1}' tox.ini
  sd -s \
  '    py313-django{52, 51}' \
  '    py314-django{52}
    py313-django{52, 51}' \
  tox.ini
  git add tox.ini
fi

git switch -c python_3.14
git commit -m "Support Python 3.14"

echo "Check below search results for more to change..."
rg -C2 --pretty --iglob '!CHANGELOG.rst' --iglob '!pyproject.toml' --iglob '!uv.lock' --iglob '!*.svg' '3\b.*\b(13|14)\b'
