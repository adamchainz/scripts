#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd -s 'py{35,36' 'py{36' tox.ini

git add tox.ini
git switch -c drop_python_3.5_followup
git commit -m "Drop more Python 3.5 references

Missed in previous PR."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
