#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

mkdir .github/ISSUE_TEMPLATE
echo 'name: Issue
description: File an issue
body:
- type: input
  id: python_version
  attributes:
    label: Python Version
    description: Which version of Python were you using?
    placeholder: 3.9.0
  validations:
    required: false
- type: input
  id: package_version
  attributes:
    label: Package Version
    description: Which version of this package were you using? If not the latest version, please check this issue has not since been resolved.
    placeholder: 1.0.0
  validations:
    required: false
- type: textarea
  id: description
  attributes:
    label: Description
    description: Please describe your issue.
  validations:
    required: true' > .github/ISSUE_TEMPLATE/issue.yml

git add .github/ISSUE_TEMPLATE/issue.yml
git switch -c issue_form
git commit -m "Add issue form"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
