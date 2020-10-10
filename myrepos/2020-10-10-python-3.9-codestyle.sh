#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd --flags ms '\[testenv:py38-codestyle.*\[' '[' tox.ini
sd 'py38-codestyle' 'py39-codestyle' tox.ini
echo '
[testenv:py39-codestyle]
deps = -rrequirements/py39.txt
commands =
    pre-commit run --all-files
    twine check .tox/dist/*' >> tox.ini

sd --string-mode '3.8.*' '3.9.*' requirements/requirements.in
requirements/compile.py

sd --string-mode 'py38-codestyle' 'py39-codestyle' .pre-commit-config.yaml

git add tox.ini requirements/ .pre-commit-config.yaml
git switch -c python_3.9_codestyle
git commit -m "Run codestyle checks with Python 3.9

Now that it's released."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
