#!/bin/sh
set -eu

git diff --exit-code
git checkout main
git pull

sd ' +- 3\.6\n' '' .github/workflows/main.yml
sd ' +py36.*\n' '' tox.ini
sd -s 'py{36,37' 'py{37' tox.ini
sd -s "target-version = ['py36']" "target-version = ['py37']" pyproject.toml
sd '\[--py36-plus' '[--py37-plus' .pre-commit-config.yaml
sd -s "Python 3.6 to " "Python 3.7 to " README.rst
sd ' +Programming Language :: Python :: 3\.6\n' '' setup.cfg
sd -s 'python_requires = >=3.6' 'python_requires = >=3.7' setup.cfg
sd -f m ' +subprocess\.run\((\n|.)*?python3\.6(\n|.)*?\)\n' '' requirements/compile.py
rm requirements/py36*txt
# shellcheck disable=SC2016
sd -f m '(=======
History
=======)' '$1

* Drop Python 3.6 support.' HISTORY.rst
git add .github/workflows/main.yml tox.ini pyproject.toml .pre-commit-config.yaml README.rst setup.cfg requirements/ HISTORY.rst

if [ -f docs/installation.rst ]; then
    sd -s "Python 3.6 to " "Python 3.7 to " README.rst
    git add docs/installation.rst
fi

git switch -c drop_python_3.6
git commit -m "Drop Python 3.6 support

Its EOL was 2021-12-23: https://www.python.org/dev/peps/pep-0494/#lifespan ."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr merge --squash --delete-branch --auto
