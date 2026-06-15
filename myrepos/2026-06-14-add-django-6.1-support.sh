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

if rg -q 61 tox.ini; then
    echo "Already testing Django 6.1, nothing to add."
    exit 0
fi

# Update declared supported versions

sd --across -s \
'  "Framework :: Django :: 6.0",' \
'  "Framework :: Django :: 6.0",
  "Framework :: Django :: 6.1",' \
pyproject.toml

# Add dependency group

sd --across -s \
$'django60 = [ "django>=6a1,<6.1; python_version>=\'3.12\'" ]' \
$'django60 = [ "django>=6a1,<6.1; python_version>=\'3.12\'" ]
django61 = [ "django>=6.1a1,<6.2; python_version>=\'3.12\'" ]' \
pyproject.toml

sd --across -s \
'    { group = "django60" },' \
'    { group = "django60" },
    { group = "django61" },' \
pyproject.toml

uv lock

# Update tox grid

sd -s 'py314-django{60, 52}' 'py314-django{61, 60, 52}' tox.ini
sd -s 'py313-django{60, 52}' 'py313-django{61, 60, 52}' tox.ini
sd -s 'py312-django{60, 52}' 'py312-django{61, 60, 52}' tox.ini

# (Old Django version cleanup)
sd --across -s \
'    django42: django42
    django50: django50
    django51: django51
' '' tox.ini

sd --across -s \
'    django60: django60' \
'    django60: django60
    django61: django61' \
tox.ini

# Update documented supported versions

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
else
    installation=README.rst
fi
sd -s \
'Django 5.2 to 6.0 supported.' \
'Django 5.2 to 6.1 supported.' \
$installation

# Add changelog entry

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi

entry="* Add Django 6.1 support."

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

git switch -c add_django_6.1_support
git commit -a -n -m "Add Django 6.1 support"

# Final checks

tox -e py314-django61 || :

pre-commit run -a || :

echo "Check below search results for more to change..."
rg --pretty --iglob '!pyproject.toml' --iglob '!uv.lock' --iglob '!CHANGELOG.rst' --iglob '!*.svg' --iglob '!*.css' --iglob '!*.js'  '\b6\b.*\b[01]\b'

git status -sb
