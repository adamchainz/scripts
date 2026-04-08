#!/bin/sh
set -eux

git diff --exit-code
git switch main
git pull

sd -s 'python: python3.13' 'python: python3.14' .pre-commit-config.yaml

# fail if no change
if git diff --exit-code; then
    echo "No change detected"
    exit 1
fi

git add --update .pre-commit-config.yaml
git switch -c pre_commit_python_3_14
git commit -m "Upgrade pre-commit to Python 3.14"

pre-commit run --all-files

git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
