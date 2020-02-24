#!/bin/sh
set -e

git switch -c python_3.9
sed -E -i '' -e 's/    Programming Language :: Python :: 3.8/    Programming Language :: Python :: 3.8\
    Programming Language :: Python :: 3.9/g' setup.cfg
sed -E -i '' -e 's/  - python: 3.8/  - python: 3.8\
  - python: 3.9-dev/g' .travis.yml
subl -w setup.cfg requirements/compile.py tox.ini .travis.yml
./requirements/compile.py
git add --all
git commit -m "Test with Python 3.9"
pushupr
