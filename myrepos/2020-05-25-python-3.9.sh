#!/bin/sh
set -e

git switch -c python_3.9
sed -E -i '' -e 's/    Programming Language :: Python :: 3.8/    Programming Language :: Python :: 3.8\
    Programming Language :: Python :: 3.9/g' setup.cfg
sed -E -i '' -e 's/        - 3.8/        - 3.8\
        - 3.9/g' .github/workflows/main.yml
subl -w .github/workflows/main.yml requirements/compile.py tox.ini setup.cfg
./requirements/compile.py
git add --all
git commit -m "Test with Python 3.9"
hub pull-request --push --no-edit -o
