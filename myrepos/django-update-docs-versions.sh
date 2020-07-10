#!/bin/sh
set -e

git switch -c django_docs_versions
# shellcheck disable=SC2016
# shellcheck disable=SC2046
sd '(docs\.djangoproject\.com/en/)(dev|[.0-9]+)/' '${1}3.0/' $(fd --type file)
git commit -a -m "Update linked version of Django docs"
gh pr create --fill
gh pr view --web
