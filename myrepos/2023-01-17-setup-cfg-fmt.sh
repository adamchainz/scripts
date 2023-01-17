#!/bin/sh
set -eux

git diff --exit-code
git sync

sd -s -- \
  '- id: trailing-whitespace' \
  '- id: trailing-whitespace
- repo: https://github.com/asottile/setup-cfg-fmt
  rev: v2.2.0
  hooks:
  - id: setup-cfg-fmt
    args:
    - --include-version-classifiers' \
  .pre-commit-config.yaml

pre-commit run setup-cfg-fmt -a || true

git add --update

git switch -c setup_cfg_fmt
git commit -m 'Add setup-cfg-fmt to pre-commit'

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
