#!/bin/zsh
set -eu

git diff --exit-code
git checkout main
git pull

sd ' +- 3\.8\n' '' .github/workflows/main.yml

sd ' +py38.*\n' '' tox.ini
# shellcheck disable=SC2016
sd '(py\{.*), 38\}' '${1}}' tox.ini

sd -- '--py38-plus' '--py39-plus' .pre-commit-config.yaml

sd '  "Programming Language :: Python :: 3.8",\n' '' pyproject.toml
sd -s 'requires-python = ">=3.8"' 'requires-python = ">=3.9"' pyproject.toml

sd -f m ' +run\((\n|.)*?"3\.8",(\n|.)*?\)\n' '' tests/requirements/compile.py
rm tests/requirements/py38*txt

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi
sd -f m '(=========
Changelog
=========)' "\$1

* Drop Python 3.8 support." $changelog

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
else
    installation=README.rst
fi
# shellcheck disable=SC2016
sd -s "Python 3.8 to " "Python 3.9 to " $installation

git add .github/workflows/main.yml tox.ini pyproject.toml .pre-commit-config.yaml README.rst tests/requirements/ $changelog $installation

git switch -c drop_python_3.8
git commit -m "Drop Python 3.8 support

Now EOL: https://discuss.python.org/t/python-3-8-is-now-officially-eol/66983 ."

pre-commit run -a || :

echo "Check below search results for more to change..."
rg --pretty --iglob '!tests/requirements/*' --iglob '!CHANGELOG.rst' '3\b.*\b(8|9)\b'

git status -sb
