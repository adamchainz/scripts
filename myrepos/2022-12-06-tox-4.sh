#!/bin/sh
set -eux

git diff --exit-code
git sync

sd -s \
  'python -m pip install --upgrade tox tox-py' \
  'python -m pip install --upgrade '"'"'tox>=4.0.0rc3'"'" \
  .github/workflows/main.yml

# shellcheck disable=SC2016
sd -s \
  'run: tox --py current' \
  'run: tox run -f py$(echo ${{ matrix.python-version }} | tr -d .)' \
  .github/workflows/main.yml

git add --update

git switch -c tox_4
git commit -m 'Upgrade to tox 4'

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
