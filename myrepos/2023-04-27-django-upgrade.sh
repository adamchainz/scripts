#!/bin/sh
set -eux

rg -q django tox.ini

git diff --exit-code
git sync

sd -s -- \
  '- repo: https://github.com/psf/black' \
  '- repo: https://github.com/adamchainz/django-upgrade
  rev: 1.13.0
  hooks:
  - id: django-upgrade
    args: [--target-version, '"'"'3.2'"'"']
- repo: https://github.com/psf/black' \
  .pre-commit-config.yaml

pre-commit run django-upgrade -a || true

git add --update

git switch -c add_django_upgrade
git commit -m 'Add django-upgrade to pre-commit'

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
