#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd -s 'runs-on: ubuntu-18.04' 'runs-on: ubuntu-20.04' .github/workflows/main.yml

git add .github/workflows/main.yml
git switch -c github_actions_ubuntu_20.04
git commit -m "Move GitHub Actios to Ubuntu 20.04"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
