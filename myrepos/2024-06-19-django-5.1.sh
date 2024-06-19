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
'  "Framework :: Django :: 5.0",' \
'  "Framework :: Django :: 5.0",
  "Framework :: Django :: 5.1",' \
pyproject.toml

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi
sd -f m '(=========
Changelog
=========)' "\$1

* Support Django 5.1." $changelog

# shellcheck disable=SC2016
git ls-files -z '*.rst' | xargs -0 sd 'Django (.*?) to 5.0 supported.' 'Django $1 to 5.1 supported.'

# shellcheck disable=SC2016
sd -s 'py312-django{50, 42}' 'py312-django{51, 50, 42}' tox.ini
sd -s 'py311-django{50, 42, 41}' 'py311-django{51, 50, 42, 41}' tox.ini
sd -s 'py310-django{50, 42, 41, 40, 32}' 'py310-django{51, 50, 42, 41, 40, 32}' tox.ini

for minor in 10 11 12; do

# shellcheck disable=SC2016
sd \
'(    run\(
        \[
            \*common_args,
            "--python",
            "3\.'$minor'",
            "--output-file",
            "py3'$minor'-django50\.txt",
        \],
        input=b"Django>=5\.0a1,<5\.1(.*?)",
    \))' \
'$1
    run(
        [
            *common_args,
            "--python",
            "3.'$minor'",
            "--output-file",
            "py3'$minor'-django51.txt",
        ],
        input=b"Django>=5.1a1,<5.2$2",
    )' \
requirements/compile.py

done

requirements/compile.py

git add --update
git add requirements
git switch -c django_5.1
git commit -m "Support Django 5.1"

tox -e py312-django51
