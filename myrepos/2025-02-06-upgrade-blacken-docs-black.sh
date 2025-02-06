#!/bin/zsh
set -eu

git diff --exit-code
git checkout main
git pull

if ! rg -q blacken-docs .pre-commit-config.yaml; then
    echo "blacken-docs not found in .pre-commit-config.yaml"
    exit 0
fi

sd 'black==\d+\.\d+\.\d+' 'black==25.1.0' .pre-commit-config.yaml

pre-commit run blacken-docs --all-files

git commit -am "Upgrade Black used by blacken-docs to 25.1.0"
