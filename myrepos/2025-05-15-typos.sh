#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

sd -s -- \
'- id: trailing-whitespace' \
'- id: trailing-whitespace
- repo: https://github.com/crate-ci/typos
  rev: 6cb49915af2e93e61f5f0d0a82216e28ad5c7c18  # frozen: v1
  hooks:
  - id: typos
    exclude: |
      (?x)^(
        .*\.min\.css
        |.*\.min\.js
        |.*\.css\.map
        |.*\.js\.map
        |.*\.svg
      )$' \
.pre-commit-config.yaml

cat > .typos.toml <<"EOF"
# Configuration file for 'typos' tool
# https://github.com/crate-ci/typos

[default]
extend-ignore-re = [
  # Single line ignore comments
  "(?Rm)^.*(#|//)\\s*typos: ignore$",
  # Multi-line ignore comments
  "(?s)(#|//)\\s*typos: off.*?\\n\\s*(#|//)\\s*typos: on"
]
EOF

git switch -c add_typos
git add .pre-commit-config.yaml .typos.toml
git commit -m "Add typos tool to pre-commit

This tool corrects common misspellings in all kinds of text files."
pre-commit run typos --all-files

# To run manually:
# git push && gh pr create --fill && sleep 1 && gh pr merge --squash --delete-branch --auto
