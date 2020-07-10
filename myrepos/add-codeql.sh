#!/bin/sh
set -e

cp ~/Documents/Projects/django-cors-headers/.github/workflows/codeql-analysis.yml .github/workflows
git switch -c codeql
git add .github/workflows/codeql-analysis.yml
git commit -a -m "Add CodeQL Analysis"
gh pr create --fill
gh pr view --web
