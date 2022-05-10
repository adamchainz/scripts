#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

sd -s 'py37-django{22,30,31,32}' 'py37-django{32}' tox.ini
sd -s 'py38-django{22,30,31,32,40}' 'py38-django{32,40}' tox.ini
sd -s 'py39-django{22,30,31,32,40}' 'py39-django{32,40}' tox.ini

sd -s 'Django>=2.2' 'Django>=3.2' setup.cfg
sd -s '    Framework :: Django :: 2.2
    Framework :: Django :: 3.0
    Framework :: Django :: 3.1
' '' setup.cfg

sd '    subprocess.run\([^)]+django22[^)]+\)\n' '' requirements/compile.py
sd '    subprocess.run\([^)]+django30[^)]+\)\n' '' requirements/compile.py
sd '    subprocess.run\([^)]+django31[^)]+\)\n' '' requirements/compile.py

rm requirements/*-django22.txt
rm requirements/*-django30.txt
rm requirements/*-django31.txt

sd 'Django 2.2 to 4.0 supported.' 'Django 3.2 to 4.0 supported.' README.rst

# shellcheck disable=SC2016
sd -f m '(=======
History
=======)' '$1

* Drop support for Django 2.2, 3.0, and 3.1.' HISTORY.rst

git add tox.ini setup.cfg requirements/ README.rst HISTORY.rst

if [ -f docs/installation.rst ]; then
  sd 'Django 2.2 to 4.0 supported.' 'Django 3.2 to 4.0 supported.' docs/installation.rst
  git add docs/installation.rst
fi

git switch -c drop_old_django_versions
git commit -m "Drop support for old Django versions

Django 2.2 is past its EOL, so drop support for it, and the intermediary versions up to the next LTS, 3.2."

# Things to manually fix
rg --pretty 'django(\.VERSION|.?2|.?3)'
