#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if ! rg -q django tox.ini; then
  echo "Skipping project not using Django."
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

sd -s \
'    Framework :: Django :: 4.0' \
'    Framework :: Django :: 4.0
    Framework :: Django :: 4.1' \
setup.cfg

sd -f m '(=======
History
=======)' "\$1

* Support Python 3.11.

* Support Django 4.1." HISTORY.rst

# shellcheck disable=SC2016
sd 'Python (.*?) to 3.10 supported.' 'Python $1 to 3.11 supported.' README.rst

# shellcheck disable=SC2016
sd 'Django (.*?) to 4.0 supported.' 'Django $1 to 4.1 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Python (.*?) to 3.10 supported.' 'Python $1 to 3.11 supported.' docs/installation.rst
  git add docs/installation.rst
fi

# shellcheck disable=SC2016
sd -s \
'    py38-django{32,40}
    py39-django{32,40}
    py310-django{32,40}' \
'    py38-django{32,40,41}
    py39-django{32,40,41}
    py310-django{32,40,41}
    py311-django{41}' \
tox.ini

for minor in 8 9 10; do

sd --string-mode \
'    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=4.0a1,<4.1",
            "-o",
            "py3'$minor'-django40.txt",
        ],
        check=True,
        capture_output=True,
    )' \
'    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=4.0a1,<4.1",
            "-o",
            "py3'$minor'-django40.txt",
        ],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=4.1a1,<4.2",
            "-o",
            "py3'$minor'-django41.txt",
        ],
        check=True,
        capture_output=True,
    )' requirements/compile.py

done

sd -s \
'    subprocess.run(
        [
            "python3.10",
            *common_args,
            "-P",
            "Django>=4.1a1,<4.2",
            "-o",
            "py310-django41.txt",
        ],
        check=True,
        capture_output=True,
    )' \
'    subprocess.run(
        [
            "python3.10",
            *common_args,
            "-P",
            "Django>=4.1a1,<4.2",
            "-o",
            "py310-django41.txt",
        ],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        [
            "python3.11",
            *common_args,
            "-P",
            "Django>=4.1a1,<4.2",
            "-o",
            "py311-django41.txt",
        ],
        check=True,
        capture_output=True,
    )' \
requirements/compile.py

requirements/compile.py

git add .github/workflows/main.yml setup.cfg HISTORY.rst README.rst tox.ini requirements/
git switch -c django_4.1
git commit -m "Support Django 4.1"
