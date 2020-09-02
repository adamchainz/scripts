#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd --string-mode 'tox tox-gh-actions' 'tox' .github/workflows/main.yml

# shellcheck disable=SC2016
sd --string-mode '      run: python -m tox' '      run: |
        ENV_PREFIX=$(tr -d "." <<< "py${{ matrix.python-version }}")
        TOXENV=$(tox --listenvs | grep $ENV_PREFIX | tr '"'"'\n'"'"' '"'"','"'"') python -m tox' .github/workflows/main.yml

sd --flags ms '\[gh-actions\][^\[]*\[' '[' tox.ini

git add .github/workflows/main.yml tox.ini
git switch -c remove_tox_gh_actions
# shellcheck disable=SC2016
git commit -m 'Remove tox-gh-actions

Use a couple of lines of shell instead. This removes the need to maintain the `[gh-actions]` section of tox.ini.'

gh pr create --fill
gh pr view --web
