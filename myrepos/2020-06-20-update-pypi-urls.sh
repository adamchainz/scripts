#!/bin/sh
set -e

git switch -c update_pypi_urls
sd 'https://pypi.python.org/pypi/' 'https://pypi.org/project/' $(fd --type file)
subl -w $(git diff --name-only)
git add --all
git commit -m "Update pypi.python.org URL to pypi.org"
gh pr create --fill
gh pr view --web
