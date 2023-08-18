#!/bin/sh
set -eu

git diff --exit-code
git checkout main
git pull

sd ' +- 3\.7\n' '' .github/workflows/main.yml

sd ' +py37.*\n' '' tox.ini
# shellcheck disable=SC2016
sd '(py\{.*38), 37' '$1' tox.ini

sd -s "target-version = ['py37']" "target-version = ['py38']" pyproject.toml

sd -- '--py37-plus' '--py38-plus' .pre-commit-config.yaml

sd ' +Programming Language :: Python :: 3\.7\n' '' setup.cfg
sd -s 'python_requires = >=3.7' 'python_requires = >=3.8' setup.cfg

sd -f m ' +subprocess\.run\((\n|.)*?python3\.7(\n|.)*?\)\n' '' requirements/compile.py
rm requirements/py37*txt

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi
sd -f m '(=========
Changelog
=========)' "\$1

* Drop Python 3.7 support." $changelog

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
else
    installation=README.rst
fi
# shellcheck disable=SC2016
sd -s "Python 3.7 to " "Python 3.8 to " $installation

git add .github/workflows/main.yml tox.ini pyproject.toml .pre-commit-config.yaml README.rst setup.cfg requirements/ $changelog $installation

git switch -c drop_python_3.7
git commit -m "Drop Python 3.7 support

EOL on 2023-06-27: https://devguide.python.org/versions/ ."

pre-commit run -a || :

echo "Check below search results for more to change..."
rg --pretty --iglob '!requirements/*' --iglob '!CHANGELOG.rst' '3\b.*\b(7|8)\b'

git status -sb
