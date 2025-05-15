#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

pre-commit autoupdate --freeze --jobs 10

git switch -c pre_commit_freeze
git add .pre-commit-config.yaml
git commit -m "Freeze pre-commit hooks

Doing so prevents surprise updates and stops pre-commit warning about mutable tags, such as on the crate-ci/typos repo."

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr merge --squash --delete-branch --auto

sleep 10
