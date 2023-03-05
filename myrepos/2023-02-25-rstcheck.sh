#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if [ -e .readthedocs.yaml ]; then
sd -s -- \
'- repo: https://github.com/asottile/pyupgrade' \
'- repo: https://github.com/rstcheck/rstcheck
  rev: v6.1.1
  hooks:
  - id: rstcheck
    additional_dependencies:
    - sphinx==6.1.3
    - tomli==2.0.1
- repo: https://github.com/asottile/pyupgrade' .pre-commit-config.yaml
else
sd -s -- \
'- repo: https://github.com/asottile/pyupgrade' \
'- repo: https://github.com/rstcheck/rstcheck
  rev: v6.1.1
  hooks:
  - id: rstcheck
    additional_dependencies:
    - tomli==2.0.1
- repo: https://github.com/asottile/pyupgrade' .pre-commit-config.yaml
fi

echo '
[tool.rstcheck]
report_level = "ERROR"' >> pyproject.toml

git add .pre-commit-config.yaml pyproject.toml
pre-commit run rstcheck -a

git switch -c rstcheck
git commit -m "Add rstcheck pre-commit hook"
git push
gh pr create --fill
gh pr view --web
