#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if rg -q -- "- '3.13'" .github/workflows/main.yml; then
  echo "Skipping project since it already supports Python 3.13."
  exit
fi

sd -s \
"        - '3.12'" \
"        - '3.12'
        - '3.13'" \
.github/workflows/main.yml


sd -s \
'  "Programming Language :: Python :: 3.12",' \
'  "Programming Language :: Python :: 3.12",
  "Programming Language :: Python :: 3.13",' \
pyproject.toml

sd -s \
'[tool.pytest.ini_options]' \
'[tool.pyproject-fmt]
max_supported_python = "3.13"

[tool.pytest.ini_options]' \
pyproject.toml

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi
sd -f m '(=========
Changelog
=========)' "\$1

* Support Python 3.13." $changelog

# shellcheck disable=SC2016
sd 'Python (.*?) to 3.12 supported.' 'Python $1 to 3.13 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Python (.*?) to 3.12 supported.' 'Python $1 to 3.13 supported.' docs/installation.rst
  git add docs/installation.rst
fi

# shellcheck disable=SC2016
sd 'py\{312, (.*?)\}' 'py{313, 312, $1}' tox.ini
sd -s \
'    py312-django{51, 50, 42}' \
'    py313-django{51}
    py312-django{51, 50, 42}' \
tox.ini

sd -s \
'    run([*common_args, "--python", "3.12", "--output-file", "py312.txt"])' \
'    run([*common_args, "--python", "3.12", "--output-file", "py312.txt"])
    run([*common_args, "--python", "3.13", "--output-file", "py313.txt"])' \
tests/requirements/compile.py

sd -s \
'    run(
        [
            *common_args,
            "--python",
            "3.12",
            "--output-file",
            "py312-django51.txt",
        ],
        input=b"Django>=5.1a1,<5.2",
    )' \
'    run(
        [
            *common_args,
            "--python",
            "3.12",
            "--output-file",
            "py312-django51.txt",
        ],
        input=b"Django>=5.1a1,<5.2",
    )
    run(
        [
            *common_args,
            "--python",
            "3.13",
            "--output-file",
            "py313-django51.txt",
        ],
        input=b"Django>=5.1a1,<5.2",
    )' \
tests/requirements/compile.py

tests/requirements/compile.py

git add .github/workflows/main.yml .pre-commit-config.yaml pyproject.toml $changelog README.rst tox.ini tests/requirements/
git switch -c python_3.13
git commit -m "Support Python 3.13"

echo "Check below search results for more to change..."
rg -C2 --pretty --iglob '!requirements/*' --iglob '!CHANGELOG.rst' --iglob '!pyproject.toml' '3\b.*\b(12|13)\b'
