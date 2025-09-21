#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if ! rg -q django tox.ini; then
  echo "Skipping project not using Django."
  exit
fi

sd -s $'django52 = [ "django>=5.2a1,<6; python_version>=\'3.10\'" ]' \
$'django52 = [ "django>=5.2a1,<6; python_version>=\'3.10\'" ]
django60 = [ "django>=6.0a1,<6.1; python_version>=\'3.12\'" ]' \
pyproject.toml

sd -s '    { group = "django52" },' \
'    { group = "django52" },
    { group = "django60" },' \
pyproject.toml

sd -s '    django52: django52' \
'    django52: django52
    django60: django60' \
tox.ini

uv lock

git add --update .
git switch -c django_6.0_correction
git commit -m "Correct testing of Django 6.0

The previous commit failed to add the appropriate uv dependency group, and the corresponding tox configuration."

tox -e py314-django60
tox -p -f django60
