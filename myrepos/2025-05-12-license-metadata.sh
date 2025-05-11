#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ ! -f pyproject.toml ]; then
    echo "pyproject.toml not found, skipping"
    exit 0
fi

if ! rg 'License :: OSI Approved :: MIT License' pyproject.toml; then
    echo "Not MIT licensed, skipping"
    exit 0
fi

if [ ! -f LICENSE ]; then
    echo "LICENSE file not found, skipping"
    exit 0
fi

sd -s '"setuptools"' '"setuptools>=77"' pyproject.toml

sd -s '[project]' \
'[project]
license = "MIT"
license-files = [ "LICENSE" ]' \
pyproject.toml

sd -s '  "License :: OSI Approved :: MIT License",
' '' pyproject.toml

pre-commit run pyproject-fmt --file pyproject.toml || true

git add pyproject.toml

git switch -c license_metadata
git commit -m "Use PEP 639 license declaration"

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr merge --squash --delete-branch --auto

sleep 10
