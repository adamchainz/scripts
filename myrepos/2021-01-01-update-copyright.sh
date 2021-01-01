#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

# shellcheck disable=SC2016
sd 'Copyright \(c\) (\d\d\d\d)-2020' 'Copyright (c) $1-2021' LICENSE
sd -s 'Copyright (c) 2020' 'Copyright (c) 2020-2021' LICENSE

git add LICENSE
git switch -c license
git commit -m "Update LICENSE year to 2021"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
