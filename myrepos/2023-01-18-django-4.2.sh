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
'    Framework :: Django :: 4.1' \
'    Framework :: Django :: 4.1
    Framework :: Django :: 4.2' \
setup.cfg

sd -f m '(=======
History
=======)' "\$1

* Support Django 4.2." HISTORY.rst

# shellcheck disable=SC2016
sd 'Django (.*?) to 4.1 supported.' 'Django $1 to 4.2 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Django (.*?) to 4.1 supported.' 'Django $1 to 4.2 supported.' docs/installation.rst
  git add docs/installation.rst
fi

# shellcheck disable=SC2016
sd -s 'py38-django{32,40,41}' 'py38-django{32,40,41,42}' tox.ini
sd -s 'py39-django{32,40,41}' 'py39-django{32,40,41,42}' tox.ini
sd -s 'py310-django{32,40,41}' 'py310-django{32,40,41,42}' tox.ini
sd -s 'py311-django{41}' 'py311-django{41,42}' tox.ini

for minor in 8 9 10 11; do

# shellcheck disable=SC2016
sd \
'(    subprocess.run\(
        \[
            "python3\.'$minor'",
            \*common_args,
            "-P",
            "Django>=4\.1a1,<4\.2",(
            "-P",
            .*,)?
            "-o",
            "py3'$minor'-django41\.txt",
        \],
        check=True,
        capture_output=True,
    \))' \
'$1
    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=4.2a1,<5.0",$2
            "-o",
            "py3'$minor'-django42.txt",
        ],
        check=True,
        capture_output=True,
    )' requirements/compile.py

done

requirements/compile.py

git add --update
git add requirements
git switch -c django_4.2
git commit -m "Support Django 4.2"
