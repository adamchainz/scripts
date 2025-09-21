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
'  "Framework :: Django :: 5.2",' \
'  "Framework :: Django :: 5.2",
  "Framework :: Django :: 6.0",' \
pyproject.toml

sd -s $'django52 = [ "django>=5.2a1,<6; python_version>=\'3.10\'" ]' \
$'django52 = [ "django>=5.2a1,<6; python_version>=\'3.10\'" ]
django60 = [ "django>=6.0a1,<6.1; python_version>=\'3.12\'" ]' \
pyproject.toml

sd -s '    { group = "django52" },' \
'    { group = "django52" },
    { group = "django60" },' \
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

* Support Django 6.0." $changelog

# shellcheck disable=SC2016
git ls-files -z '*.rst' | xargs -0 sd 'Django (.*?) to 5.2 supported.' 'Django $1 to 6.0 supported.'

# shellcheck disable=SC2016
sd -s 'py314-django{52}' 'py314-django{60, 52}' tox.ini
sd -s 'py313-django{52, 51}' 'py313-django{60, 52, 51}' tox.ini
sd -s 'py312-django{52, 51, 50, 42}' 'py312-django{60, 52, 51, 50, 42}' tox.ini
sd -s '    django52: django52' \
'    django52: django52
    django60: django60' \
tox.ini

uv lock

git add --update .
git switch -c django_6.0
git commit -m "Support Django 6.0"

tox -e py314-django60
tox -p -f django60
