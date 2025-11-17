#!/bin/zsh
set -eu

git diff --exit-code
git checkout main
git pull

if ! rg -q -- "- '3.9'" .github/workflows/main.yml; then
  echo "Skipping project since it doesn't support Python 3.9."
  exit
fi

sd -s 'placeholder: 3.9.0' 'placeholder: 3.14.0' .github/ISSUE_TEMPLATE/issue.yml

sd $' +- \'3\.9\'\n' '' .github/workflows/main.yml

sd ' +py39.*\n' '' tox.ini
# shellcheck disable=SC2016
sd '(py\{.*), 39\}' '${1}}' tox.ini

sd '  "Programming Language :: Python :: 3.9",\n' '' pyproject.toml
sd -s 'requires-python = ">=3.9"' 'requires-python = ">=3.10"' pyproject.toml

uv lock

if [ -f docs/changelog.rst ]; then
    changelog=docs/changelog.rst
else
    changelog=CHANGELOG.rst
fi
sd -f m '(=========
Changelog
=========)' "\$1

* Drop Python 3.9 support." $changelog

if [ -f docs/installation.rst ]; then
    installation=docs/installation.rst
else
    installation=README.rst
fi
# shellcheck disable=SC2016
sd -s "Python 3.9 to " "Python 3.10 to " $installation

git add .github/ISSUE_TEMPLATE/issue.yml .github/workflows/main.yml tox.ini pyproject.toml uv.lock README.rst $changelog $installation

git switch -c drop_python_3.9
git commit -m "Drop Python 3.9 support

It reached EOL on 2025-10-31: https://peps.python.org/pep-0596/#lifespan."

gh-branch-protection-checks.py remove main 'Python 3.9'

pre-commit run -a || :

echo "Check below search results for more to change..."
rg -C2 --pretty --iglob '!CHANGELOG.rst' --iglob '!uv.lock' --iglob '!*.svg' --glob '!*.js' --glob '!*.css' '3\b.*\b(9|10)\b'

git status -sb
