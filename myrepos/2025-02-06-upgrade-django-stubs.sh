#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if ! rg -q django-stubs .pre-commit-config.yaml; then
    echo "django-stubs not found in .pre-commit-config.yaml"
    exit 0
fi

sd 'django-stubs==\d+\.\d+\.\d+' 'django-stubs==5.1.2' .pre-commit-config.yaml

pre-commit run mypy --all-files

git commit -am "Upgrade django-stubs to 5.1.2"
