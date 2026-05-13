#!/bin/sh
set -eux

git diff --exit-code
git switch main
git pull

if [ ! -f .readthedocs.yaml ]; then
    echo ".readthedocs.yaml not found"
    exit 0
fi

if rg -q 'method: uv' .readthedocs.yaml; then
    echo "Already using uv method in .readthedocs.yaml"
    exit 0
fi

python3 << 'PYTHON'
import re, sys

with open(".readthedocs.yaml") as f:
    text = f.read()

text = re.sub(r'  jobs:\n(.+\n)+', '', text)
text = text.replace('sphinx:', 'python:\n  install:\n    - method: uv\n      command: sync\n      groups:\n        - docs\n\nsphinx:')

with open(".readthedocs.yaml", "w") as f:
    f.write(text)
PYTHON

git add --update .readthedocs.yaml
git switch -c update_readthedocs_uv_config
git commit -m "Use Read the Docs native uv support

Per https://about.readthedocs.com/blog/2026/04/uv-native-support/."

git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
gh pr view --web
