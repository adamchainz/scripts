#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd '3.9-dev' '3.9' .github/workflows/main.yml
sd 'actions/setup-python@v2.1.1' 'actions/setup-python@v2' .github/workflows/main.yml

git add .github/workflows/main.yml
git switch -c python_3.9
git commit -m "Test with Python 3.9.0

Move from the dev version to first release."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
