#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ ! -f .pre-commit-config.yaml ]; then
    echo "No .pre-commit-config.yaml, nothing to do."
    exit 0
fi

if ! rg -q -- '- django-stubs==' .pre-commit-config.yaml; then
    echo "django-stubs not found, nothing to do."
    exit 0
fi

sd -- \
'- django-stubs==.*' \
'- django-stubs==6.1.0' \
.pre-commit-config.yaml

# Check mypy passes before committing

pre-commit run -a mypy

# Commit

git switch -c django_stubs_6.1.0
git commit -a -n -m "Upgrade django-stubs to 6.1.0"

git push && gh pr create --fill && sleep 1 && gh pr merge --squash --delete-branch --auto
