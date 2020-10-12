#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

# shellcheck disable=SC2016
sd '\.\. image:: https://github\.com/([^/]+)/([^/]+)/workflows/CI/badge\.svg\?branch=master' '.. image:: https://img.shields.io/github/workflow/status/$1/$2/CI/master?style=for-the-badge' README.rst
# shellcheck disable=SC2016
sd '(\.\. image:: https://img\.shields\.io/pypi.*)' '$1?style=for-the-badge' README.rst
# shellcheck disable=SC2016
sd '(\.\. image:: https://img\.shields\.io/badge/code%20style.*)' '$1?style=for-the-badge' README.rst
# shellcheck disable=SC2016
sd '(\.\. image:: https://img\.shields\.io/badge/pre--commit.*)' '$1&style=for-the-badge' README.rst

sd --string-mode ':target: https://github.com/python/black' ':target: https://github.com/psf/black' README.rst

git add README.rst
git switch -c bigger_badges
git commit -m "Use 'for-the-badge' style

Easier to read, so more visible and accessible."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
