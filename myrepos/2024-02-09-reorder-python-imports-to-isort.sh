#!/bin/sh
# shellcheck disable=SC2016
set -eux

git diff --exit-code
git checkout main
git pull

sd -- \
    '(?sm)- repo: https://github.com/asottile/reorder-python-imports.*import annotations.' \
    '- repo: https://github.com/pycqa/isort
  rev: 5.13.2
  hooks:
    - id: isort
      name: isort (python)' \
    .pre-commit-config.yaml

echo '[tool.isort]
add_imports = [
    "from __future__ import annotations"
]
force_single_line = true
profile = "black"' >> pyproject.toml

# reformat
pre-commit run pyproject-fmt --file pyproject.toml || true
pre-commit run isort -a || true

git switch -c isort
git commit -am "Use isort to sort imports

Switching because reorder-python-imports is incompatible with Black 24: https://github.com/asottile/reorder-python-imports/issues/366  / https://github.com/psf/black/issues/4175 ."

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web

