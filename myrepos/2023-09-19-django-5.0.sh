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
'    Framework :: Django :: 4.2' \
'    Framework :: Django :: 4.2
    Framework :: Django :: 5.0' \
setup.cfg

sd -f m '(=========
Changelog
=========)' "\$1

* Support Django 5.0." CHANGELOG.rst

# shellcheck disable=SC2016
sd 'Django (.*?) to 4.2 supported.' 'Django $1 to 5.0 supported.' README.rst

if [ -f docs/installation.rst ]; then
  # shellcheck disable=SC2016
  sd 'Django (.*?) to 4.2 supported.' 'Django $1 to 5.0 supported.' docs/installation.rst
  git add docs/installation.rst
fi

# shellcheck disable=SC2016
sd -s 'py312-django{42}' 'py312-django{50, 42}' tox.ini
sd -s 'py311-django{42, 41}' 'py311-django{50, 42, 41}' tox.ini
sd -s 'py310-django{42, 41, 40, 32}' 'py310-django{50, 42, 41, 40, 32}' tox.ini

for minor in 10 11 12; do

# shellcheck disable=SC2016
sd \
'(    subprocess.run\(
        \[
            "python3\.'$minor'",
            \*common_args,
            "-P",
            "Django>=4\.2a1,<5\.0",(
            "-P",
            .*,)?
            "-o",
            "py3'$minor'-django42\.txt",
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
            "Django>=5.0a1,<5.1",$2
            "-o",
            "py3'$minor'-django50.txt",
        ],
        check=True,
        capture_output=True,
    )' requirements/compile.py

done

requirements/compile.py

git add --update
git add requirements
git switch -c django_5.0
git commit -m "Support Django 5.0"

tox -e py312-django50
