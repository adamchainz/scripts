#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

echo 'repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v3.4.0
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
  - id: flake8
    additional_dependencies:
    - flake8-bugbear
    - flake8-comprehensions
    - flake8-tidy-imports
- repo: https://github.com/mgedmin/check-manifest
  rev: "0.45"
  hooks:
  - id: check-manifest
    args: [--no-build-isolation]' > .pre-commit-config.yaml

sd -s 'select = C,E,F,W,B,B950' 'select = E,F,W,B,B950,C,I' setup.cfg

git add .pre-commit-config.yaml setup.cfg
pre-commit run flake8 --all-files
pre-commit run check-manifest --all-files
git switch -c pre_commit_hooks
git commit -m "Update pre-commit config

* Add check-manifest
* Add flake8 plugins missed in migration"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
