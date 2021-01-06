#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd --string-mode 'pip install --upgrade coveralls' 'pip install --upgrade codecov' .github/workflows/main.yml
sd --string-mode 'coveralls --rcfile=setup.cfg' 'codecov' .github/workflows/main.yml

# shellcheck disable=SC2016
sd 'https://img\.shields\.io/coveralls/github/(.*?)/(.*?)/master?style=for-the-badge' \
   'https://img\.shields\.io/codecov/c/github/$1/$2/master?style=for-the-badge' \
   README.rst
# shellcheck disable=SC2016
sd 'https://coveralls.io/r/(.*?)/(.*?)' \
   'https://app.codecov.io/gh/$1/$2' \
   README.rst

git add .github/workflows/main.yml README.rst
git switch -c codecov
git commit -m "Move code coverage collection to codecov"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
