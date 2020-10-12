#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd --string-mode ':target: https://github.com/python/black' ':target: https://github.com/python/black

.. image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
   :target: https://github.com/pre-commit/pre-commit
   :alt: pre-commit' README.rst

git add README.rst
git switch -c pre_commit_badge
git commit -m "Add pre-commit badge

As per https://pre-commit.com/#badging-your-repository"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
