#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

sd --string-mode -- '- repo: https://github.com/pycqa/isort' '- repo: https://github.com/asottile/blacken-docs
  rev: v1.10.0
  hooks:
  - id: blacken-docs
    additional_dependencies:
    - black==21.7b0
- repo: https://github.com/pycqa/isort' .pre-commit-config.yaml

git add .pre-commit-config.yaml
git switch -c blacken_docs
git commit -m "Add blacken-docs pre-commit hook"

pre-commit run blacken-docs --all
