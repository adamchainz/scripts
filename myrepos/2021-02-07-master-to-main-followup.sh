#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

# shellcheck disable=SC2046
sd 'master' 'main' $(git ls-files)

git add --patch
git switch -c master_to_main
git commit -m "Replace leftover 'master' references with 'main'"
git restore .

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
