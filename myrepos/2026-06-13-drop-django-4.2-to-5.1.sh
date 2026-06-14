#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ ! -f tox.ini ]; then
    echo "tox.ini not found"
    exit 0
fi

if ! rg -q django tox.ini; then
    echo "Not a Django project."
    exit 0
fi

if ! rg -q 42 tox.ini; then
    echo "Not testing Django 4.2, nothing to drop."
    exit 0
fi

# Update tox grid

sd -s 'py313-django{60, 52, 51}' 'py313-django{60, 52}' tox.ini
sd -s 'py312-django{60, 52, 51, 50, 42}' 'py312-django{60, 52}' tox.ini
sd -s 'py311-django{52, 51, 50, 42}' 'py311-django{52}' tox.ini
sd -s 'py310-django{52, 51, 50, 42}' 'py310-django{52}' tox.ini

# Update declared supported versions

sd -s '"django>=4.2"' '"django>=5.2"' pyproject.toml

sd --across -s '  "Framework :: Django :: 4.2",
  "Framework :: Django :: 5.0",
  "Framework :: Django :: 5.1",
' '' pyproject.toml

# Remove dependency groups

sd --across '^django42 = \[.*\]\n' '' pyproject.toml
sd --across '^django50 = \[.*\]\n' '' pyproject.toml
sd --across '^django51 = \[.*\]\n' '' pyproject.toml

sd --across -s '    { group = "django42" },
' '' pyproject.toml
sd --across -s '    { group = "django50" },
' '' pyproject.toml
sd --across -s '    { group = "django51" },
' '' pyproject.toml

uv lock

# Update documented supported versions

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
else
    installation=README.rst
fi
sd 'Django 4.2 to 6.0 supported.' 'Django 5.2 to 6.0 supported.' $installation

# Update django-stubs

sd -s 'django-stubs==5.1.2' 'django-stubs==6.0.5' .pre-commit-config.yaml

# Add changelog entry

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi

entry="* Drop Django 4.2 to 5.1 support."

sd --across -f m '(=========
Changelog
=========

Unreleased
----------)' "\$1

$entry" "$changelog"

if git diff --exit-code "$changelog" >/dev/null; then
    sd --across -f m '(=========
Changelog
=========)' "\$1

Unreleased
----------

$entry" "$changelog"
fi

# Commit

git switch -c drop_django_4.2_to_5.1_support
git commit -a -n -m "Drop Django 4.2 to 5.1 support

These versions are all EOL since April."

# Final checks

pre-commit run -a || :

echo "Check below search results for more to change..."
rg --pretty --iglob '!pyproject.toml' --iglob '!uv.lock' --iglob '!CHANGELOG.rst' --iglob '!*.svg' --iglob '!*.css' --iglob '!*.js'  '(\b4\b.*\b2\b|\b5\b.*\b(0|1|2)\b)'

git status -sb
