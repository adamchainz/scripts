#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if ! rg -q django pyproject.toml; then
    echo "django not found in pyproject.toml"
    exit 0
fi

sd --flags s '(test = \[.*?)  "django",\n(.*?\]\n)' '$1$2' pyproject.toml

uv lock

git add pyproject.toml uv.lock

git switch -c uv_simplify
git commit -m "Simplify specifying Django test dependency"

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
gh pr merge --squash --delete-branch --auto
