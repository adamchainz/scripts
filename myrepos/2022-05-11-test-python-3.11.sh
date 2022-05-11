#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if rg -q django tox.ini; then
  echo "Skipping project using Django, since only Django 4.1 will support Python 3.11."
  exit
fi

sd -s \
"        - '3.10'" \
"        - '3.10'
        - '3.11-dev'" \
.github/workflows/main.yml

sd -s \
'    Programming Language :: Python :: 3.10' \
'    Programming Language :: Python :: 3.10
    Programming Language :: Python :: 3.11' \
setup.cfg

sd -f m '(=======
History
=======)' "\$1

* Support Python 3.11." HISTORY.rst

# shellcheck disable=SC2016
sd 'Python (.*?) to 3.10 supported.' 'Python $1 to 3.11 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Python (.*?) to 3.10 supported.' 'Python $1 to 3.11 supported.' docs/installation.rst
  git add docs/installation.rst
fi

# shellcheck disable=SC2016
sd 'py\{(.*?),310\}' 'py{$1,310,311}' tox.ini

sd -s \
'    subprocess.run(
        ["python3.10", *common_args, "-o", "py310.txt"],
        check=True,
        capture_output=True,
    )' \
'    subprocess.run(
        ["python3.10", *common_args, "-o", "py310.txt"],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        ["python3.11", *common_args, "-o", "py311.txt"],
        check=True,
        capture_output=True,
    )' \
requirements/compile.py

requirements/compile.py

git add .github/workflows/main.yml setup.cfg HISTORY.rst README.rst tox.ini requirements/
git switch -c python_3.11
git commit -m "Support Python 3.11"

echo "Check below search results for more to change..."
rg --pretty '3\b.*\b(10|11)\b'
