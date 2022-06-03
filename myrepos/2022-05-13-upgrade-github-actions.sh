#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

sd -s 'actions/checkout@v2' 'actions/checkout@v3' .github/workflows/*.yml
sd -s 'actions/download-artifact@v2' 'actions/download-artifact@v3' .github/workflows/*.yml
sd -s 'actions/setup-python@v2' 'actions/setup-python@v3' .github/workflows/*.yml
sd -s 'actions/upload-artifact@v2' 'actions/upload-artifact@v3' .github/workflows/*.yml
sd -s 'docker/setup-qemu-action@v1' 'docker/setup-qemu-action@v2' .github/workflows/*.yml

git add .github/workflows/*.yml
git switch -c upgrade_github_actions
git commit -m "Upgrade GitHub Actions

New versions use Node 16."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web

sleep 10
