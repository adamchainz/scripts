#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd ' +- 3\.5\n' '' .github/workflows/main.yml
sd ' +py35.*\n' '' tox.ini
sd -f m '^\[testenv:py35(\n|.)*?\[testenv:py36' '[testenv:py36' tox.ini
sd -s "target-version = ['py35']" "target-version = ['py36']" pyproject.toml
sd -s "Python 3.5 to " "Python 3.6 to " README.rst
sd ' +Programming Language :: Python :: 3.5\n' '' setup.cfg
sd -s 'python_requires = >=3.5' 'python_requires = >=3.6' setup.cfg
sd -f m ' +subprocess\.run\((\n|.)*?python3\.5(\n|.)*?\)\n' '' requirements/compile.py
rm requirements/py35*txt
# shellcheck disable=SC2016
sd -f m '(=======
History
=======)' '$1

* Drop Python 3.5 support.' HISTORY.rst

git add .github/workflows/main.yml tox.ini pyproject.toml README.rst setup.cfg requirements/ HISTORY.rst
git switch -c drop_python_3.5
git commit -m "Drop Python 3.5 support

Python 3.5 ended support by the PSF on 2020-09-30."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
