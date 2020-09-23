#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

# shellcheck disable=SC2039
ed .pre-commit-config.yaml <<< '0a
repos:
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
.
w'

git add .pre-commit-config.yaml
git switch -c pre_commit_hooks
git commit -m 'Add pre-commit-hooks

More code quality checks. Also migrate to top-level map config.'

tox -e py38-codestyle || true
git add .
git commit --amend --reuse-message=HEAD
tox -e py38-codestyle

gh pr create --fill
gh pr view --web
