#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if ! rg -q -- "- '3.11'" .github/workflows/main.yml; then
  echo "Skipping project since it doesn't support Python 3.11."
  exit
fi

sd -s \
"        - '3.11'" \
"        - '3.11'
        - '3.12'" \
.github/workflows/main.yml

sd -s \
"        cache: pip" \
"        allow-prereleases: true
        cache: pip" \
.github/workflows/main.yml

sd -s \
'    Programming Language :: Python :: 3.11' \
'    Programming Language :: Python :: 3.11
    Programming Language :: Python :: 3.12' \
setup.cfg

sd -s \
'    - --include-version-classifiers' \
'    - --include-version-classifiers
    - --max-py-version
    - '"'"'3.12'"'" \
.pre-commit-config.yaml

sd -f m '(=========
Changelog
=========)' "\$1

* Support Python 3.12." CHANGELOG.rst

# shellcheck disable=SC2016
sd 'Python (.*?) to 3.11 supported.' 'Python $1 to 3.12 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Python (.*?) to 3.11 supported.' 'Python $1 to 3.12 supported.' docs/installation.rst
  git add docs/installation.rst
fi

# shellcheck disable=SC2016
sd 'py\{311, (.*?)\}' 'py{312, 311, $1}' tox.ini
sd -s \
'    py311-django{42, 41}' \
'    py312-django{42}
    py311-django{42, 41}' \
tox.ini
sd -s \
'[testenv]' \
'[testenv]
package = wheel' \
tox.ini

sd -s \
'    subprocess.run(
        ["python3.11", *common_args, "-o", "py311.txt"],
        check=True,
        capture_output=True,
    )' \
'    subprocess.run(
        ["python3.11", *common_args, "-o", "py311.txt"],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        ["python3.12", *common_args, "-o", "py312.txt"],
        check=True,
        capture_output=True,
    )' \
requirements/compile.py

sd -s \
'    subprocess.run(
        [
            "python3.11",
            *common_args,
            "-P",
            "Django>=4.2a1,<5.0",
            "-o",
            "py311-django42.txt",
        ],
        check=True,
        capture_output=True,
    )' \
'    subprocess.run(
        [
            "python3.11",
            *common_args,
            "-P",
            "Django>=4.2a1,<5.0",
            "-o",
            "py311-django42.txt",
        ],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        [
            "python3.12",
            *common_args,
            "-P",
            "Django>=4.2a1,<5.0",
            "-o",
            "py312-django42.txt",
        ],
        check=True,
        capture_output=True,
    )' \
requirements/compile.py

requirements/compile.py

git add .github/workflows/main.yml .pre-commit-config.yaml setup.cfg CHANGELOG.rst README.rst tox.ini requirements/
git switch -c python_3.12
git commit -m "Support Python 3.12"

echo "Check below search results for more to change..."
rg --pretty '3\b.*\b(11|12)\b'
