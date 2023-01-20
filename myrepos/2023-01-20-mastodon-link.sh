#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

if ! rg -q 'Twitter = https://twitter.com/adamchainz' setup.cfg; then
  echo "Skipping project without Twitter link."
  exit
fi

sd -s \
'    Twitter = https://twitter.com/adamchainz' \
'    Mastodon = https://fosstodon.org/@adamchainz
    Twitter = https://twitter.com/adamchainz' \
setup.cfg

git add --update
git commit -m "Add Mastodon link to PyPI"
git push
