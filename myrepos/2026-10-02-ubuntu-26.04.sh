#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

files=(.github/workflows/*.yml(N))
if [ -f .readthedocs.yaml ]; then
    files+=(.readthedocs.yaml)
fi

if ! rg -q 'ubuntu-2[24]\.04' "${files[@]}"; then
    echo "No old Ubuntu versions found, nothing to migrate."
    exit 0
fi

# GitHub Actions: runs-on, including ubuntu-24.04-arm and expressions
# Read the Docs: build.os
sd 'ubuntu-2[24]\.04' 'ubuntu-26.04' "${files[@]}"

git switch -c ubuntu_26.04
git add --update "${files[@]}"
git commit -m "Upgrade to Ubuntu 26.04"

git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
