#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

echo "This project follows [Django's Code of Conduct](https://www.djangoproject.com/conduct/)." > .github/CODE_OF_CONDUCT.md

echo "Please report security issues directly over email to me@adamj.eu" > .github/SECURITY.md

git add .github
git switch -c github_docs
git commit -m 'Add GitHub Code of Conduct and Security Policy

These appear in the GitHub UI as per [their documentation](https://docs.github.com/en/github/building-a-strong-community/creating-a-default-community-health-file).'

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
