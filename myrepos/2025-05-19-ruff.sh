#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

# Add Ruff to pre-commit
sd -s -- \
'- repo: https://github.com/PyCQA/flake8' \
'- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: 12753357c00c3fb8615100354c9fdc6ab80b044d  # frozen: v0.11.10
  hooks:
    - id: ruff-check
      args: [ --fix ]
    - id: ruff-format
- repo: https://github.com/PyCQA/flake8' \
.pre-commit-config.yaml

# Drop old tools
sd -f ms -- \
'- repo: https://github\.com/psf/black-pre-commit-mirror\n( +[^\n]+\n)+' \
'' \
.pre-commit-config.yaml

sd -f ms -- \
'- repo: https://github\.com/asottile/pyupgrade\n( +[^\n]+\n)+' \
'' \
.pre-commit-config.yaml

sd -f ms -- \
'- repo: https://github\.com/pycqa/isort\n( +[^\n]+\n)+' \
'' \
.pre-commit-config.yaml

sd -f ms -- \
'- repo: https://github\.com/PyCQA/flake8\n( +[^\n]+\n)+' \
'' \
.pre-commit-config.yaml

# Drop old configuration

if [ -f tox.ini ]; then
    sd -f s '\n\[flake8\].*' '' tox.ini
    git add tox.ini
fi

sd -f s '\[tool.isort\]\n([^\[\n][^\n]*?\n)+' '' pyproject.toml

# Add Ruff configuration
echo '[tool.ruff]
lint.select = [
  # flake8-bugbear
  "B",
  # flake8-comprehensions
  "C4",
  # pycodestyle
  "E",
  # Pyflakes errors
  "F",
  # isort
  "I",
  # flake8-simplify
  "SIM",
  # flake8-tidy-imports
  "TID",
  # pyupgrade
  "UP",
  # Pyflakes warnings
  "W",
]
lint.ignore = [
  # flake8-bugbear opinionated rules
  "B9",
  # line-too-long
  "E501",
  # suppressible-exception
  "SIM105",
  # if-else-block-instead-of-if-exp
  "SIM108",
]
lint.extend-safe-fixes = [
  # non-pep585-annotation
  "UP006",
]
lint.isort.required-imports = [ "from __future__ import annotations" ]' >> pyproject.toml

git switch -c ruff
pre-commit run pyproject-fmt --all-files >/dev/null || true
git add .pre-commit-config.yaml pyproject.toml
git commit -m "Migrate formatting and linting to Ruff"
pre-commit run ruff-check --all-files || true
pre-commit run ruff-format --all-files || true
pre-commit run ruff-check --all-files

# To run manually:
# gcf && git push && gh pr create --fill && sleep 1 && gh pr merge --squash --delete-branch --auto
