#!/bin/bash
set -e

git diff --exit-code
git checkout master
git pull

sd --flags m '\n\[isort\]([^\[]*)' '' setup.cfg

echo '
[tool.isort]
profile = "black"' >> pyproject.toml

git add setup.cfg pyproject.toml

git switch -c isort_config
git commit -m "Upgrade isort config for version 5"
gh pr create --fill
gh pr view --web
