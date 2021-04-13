#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

subl -w .github/workflows/main.yml README.rst

git add .github/workflows/main.yml README.rst
git switch -c remove_coveralls_references
git commit -m "Remove old coveralls references."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
