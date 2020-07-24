#!/bin/bash
set -e

git diff --exit-code
git checkout master
git pull

echo '- repo: local
  hooks:
  - id: black
    name: black
    entry: .tox/py38-codestyle/bin/black
    language: system
    types: [python]
  - id: check-manifest
    name: check-manifest
    entry: check-manifest
    language: system
    pass_filenames: false
    files: ^MANIFEST\.in$
  - id: flake8
    name: flake8
    entry: .tox/py38-codestyle/bin/flake8 --config=setup.cfg
    language: system
    types: [python]
  - id: isort
    name: isort
    entry: .tox/py38-codestyle/bin/isort
    language: system
    types: [python]' > .pre-commit-config.yaml

sd -s 'exclude .editorconfig' 'exclude .editorconfig
exclude .pre-commit-config.yaml' MANIFEST.in

sd --flags m '\nmultilint ;.*$' '' requirements/requirements.in
echo "pre-commit ; python_version == '3.8.*'" >> requirements/requirements.in
sort requirements/requirements.in -o requirements/requirements.in
./requirements/compile.py

sd --flags m '\n\[tool:multilint\]([^\[]*)' '' setup.cfg

sd -s '    multilint
    check-manifest' '    pre-commit run --all-files' tox.ini

git add .pre-commit-config.yaml MANIFEST.in requirements/ setup.cfg tox.ini

tox -r -e py38-codestyle

git switch -c pre-commit && git commit -m "Move linting from multilint to pre-commit" && gh pr create --fill && gh pr view --web
