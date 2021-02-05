#!/bin/sh
set -e

git branch -m master main
git fetch origin
git branch -u origin/main main
git fetch origin --prune
