#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

# shellcheck disable=SC2046
sd 'graft tests' 'prune tests' MANIFEST.in
sd -f m '(=======
History
=======)' "\$1

* Stop distributing tests to reduce package size. Tests are not intended to be
  run outside of the tox setup in the repository. Repackagers can use GitHub's
  tarballs per tag." HISTORY.rst

git add MANIFEST.in HISTORY.rst
git switch -c stop_distributing_tests
git commit -m "Stop distributing tests to reduce package size."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
