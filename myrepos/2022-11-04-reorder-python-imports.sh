#!/bin/sh
set -eux

git diff --exit-code
git sync

# from pypugrade
version_flag=$(rg --pcre2 -o '(?<=args: \[)--py\d+-plus' .pre-commit-config.yaml)

sd -s -- '- repo: https://github.com/pycqa/isort
  rev: 5.10.1
  hooks:
  - id: isort' "- repo: https://github.com/asottile/reorder_python_imports
  rev: v3.9.0
  hooks:
  - id: reorder-python-imports
    args:
    - $version_flag
    - --application-directories
    - .:example:src
    - --add-import
    - 'from __future__ import annotations'" .pre-commit-config.yaml

sd -f m '\[tool\.isort\](\n|.)+?\[' '[' pyproject.toml

pre-commit run reorder-python-imports --all || true
pre-commit run --all || true

git add --update

git switch -c reorder_python_imports
# shellcheck disable=SC1112
git commit -m 'Move from isort to reorder-python-imports

It’s [way faster](https://twitter.com/codewithanthony/status/1553034384206438401) and its one-import-per-line style prevents merge conflicts.'

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
