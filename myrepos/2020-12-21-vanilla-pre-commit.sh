#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd -f m '^.*; python_version == .*\n' '' requirements/requirements.in
requirements/compile.py

sd -f m '^( )+py39-codestyle\n' '' tox.ini
sd -f m '^\n\[testenv:py39-codestyle(\n|[^\[])*' '' tox.ini

echo 'repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v3.2.0
  hooks:
  - id: check-added-large-files
  - id: check-case-conflict
  - id: check-json
  - id: check-merge-conflict
  - id: check-symlinks
  - id: check-toml
  - id: end-of-file-fixer
  - id: trailing-whitespace
- repo: https://github.com/psf/black
  rev: 20.8b1
  hooks:
  - id: black
    language_version: python3
- repo: https://github.com/pycqa/isort
  rev: 5.6.4
  hooks:
  - id: isort
- repo: https://gitlab.com/pycqa/flake8
  rev: 3.8.4
  hooks:
  - id: flake8' > .pre-commit-config.yaml

git add requirements tox.ini .pre-commit-config.yaml
git switch -c vanilla_pre_commit
git commit -m "Use vanilla pre-commit

Working with it inside tox simplified some things but complicated many more. Using vanilla pre-commit is a more supporte approach and will allow use of the pre-commit.ci service."

pre-commit install
pre-commit run --all-files

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
