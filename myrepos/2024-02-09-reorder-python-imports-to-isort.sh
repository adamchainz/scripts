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

if [ -d example ]; then
    echo 'src_paths = [
    ".",
    "example",
    "src",
]' >> pyproject.toml
fi

# reformat
pre-commit run pyproject-fmt --file pyproject.toml || true
pre-commit run isort -a || true
pre-commit run -a

git commit -am "Use isort to sort imports"
git push
