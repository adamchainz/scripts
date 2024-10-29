#!/bin/zsh
set -eu

git diff --exit-code
git checkout main
git pull

# Update tox grid

sd -s 'py311-django{51, 50, 42, 41}' 'py311-django{51, 50, 42}' tox.ini
sd -s 'py310-django{51, 50, 42, 41, 40, 32}' 'py310-django{51, 50, 42}' tox.ini
sd -s 'py39-django{42, 41, 40, 32}' 'py39-django{42}' tox.ini

# Update declared supported versions

sd -s 'django>=3.2' 'django>=4.2' pyproject.toml

sd -s '  "Framework :: Django :: 3.2",
  "Framework :: Django :: 4.0",
  "Framework :: Django :: 4.1",
' '' pyproject.toml

# Remove old test requirements

sd '    run\([^)]+django32[^)]+\)\n' '' tests/requirements/compile.py
sd '    run\([^)]+django40[^)]+\)\n' '' tests/requirements/compile.py
sd '    run\([^)]+django41[^)]+\)\n' '' tests/requirements/compile.py

rm tests/requirements/*-django32.txt
rm tests/requirements/*-django40.txt
rm tests/requirements/*-django41.txt

# Update documented supported versions

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
else
    installation=README.rst
fi
sd 'Django 3.2 to 5.1 supported.' 'Django 4.2 to 5.1 supported.' $installation

# Add changelog entry

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi

entry="* Drop Django 3.2 to 4.1 support."

sd -f m '(=========
Changelog
=========

Unreleased
----------)' "\$1

$entry" "$changelog"

if git diff --exit-code "$changelog" >/dev/null; then
    sd -f m '(=========
Changelog
=========)' "\$1

Unreleased
----------

$entry" "$changelog"
fi

# Update django-upgrade target-version

sd -s -- $'- repo: https://github.com/adamchainz/django-upgrade
  rev: 1.21.0
  hooks:
  - id: django-upgrade
    args: [--target-version, \'3.2\']' \
$'- repo: https://github.com/adamchainz/django-upgrade
  rev: 1.21.0
  hooks:
  - id: django-upgrade
    args: [--target-version, \'4.2\']' \
.pre-commit-config.yaml

pre-commit run django-upgrade -a || :

# Commit

git switch -c drop_old_django_versions
git commit -a -n -m "Drop Django 3.2 to 4.1 support

These versions are all EOL since April."

# Final checks

pre-commit run -a || :

echo "Check below search results for more to change..."
rg --pretty --iglob '!tests/requirements/*' --iglob '!CHANGELOG.rst' '(\b3\b.*\b2\b|\b4\b.*\b(0|1|2)\b)'

git status -sb
