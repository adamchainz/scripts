#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

sd -s '[tool.isort]
profile = "black"' '[tool.isort]
profile = "black"
add_imports = "from __future__ import annotations"' pyproject.toml
pre-commit run isort --all-files || true
pre-commit run pyupgrade --all-files || true
git ls-files -- '*.py' | xargs ~/tmp/unimport/venv/bin/autoflake --in-place || true
pre-commit run --all-files || true

git add pyproject.toml
git ls-files -- '*.py' | xargs git add

git switch -c future_annotations
git commit -m "Add __future__.annotations to all files

Makes type hints futuristic."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
