#!/bin/sh
set -e

git switch -c github-actions
mkdir -p .github/workflows
# shellcheck disable=SC2016
# shellcheck disable=SC1004
echo 'name: CI

on:
  push:
    branches:
    - master
  pull_request:
    branches:
    - master

jobs:
  tests:
    name: Python ${{ matrix.python-version }}
    runs-on: ubuntu-18.04

    strategy:
      matrix:
        python-version:
        - 3.5
        - 3.6
        - 3.7
        - 3.8

    steps:
    - uses: actions/checkout@v2
    - uses: actions/setup-python@v1
      with:
        python-version: ${{ matrix.python-version }}
    - uses: actions/cache@v1
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('"'"'requirements/*.txt'"'"') }}
        restore-keys: |
          ${{ runner.os }}-pip-
    - name: Upgrade packaging tools
      run: python -m pip install --upgrade pip setuptools virtualenv
    - name: Install dependencies
      run: python -m pip install --upgrade tox tox-gh-actions
    - name: Run tox targets for ${{ matrix.python-version }}
      run: python -m tox' > .github/workflows/main.yml
sed -E -i '' -e 's/\[testenv\]/[gh-actions]\
python =\
    3.5: py35\
    3.6: py36\
    3.7: py37\
    3.8: py38, py38-codestyle\
\
[testenv]/g' tox.ini
sed -E -i '' '/install_command/d' tox.ini
sed -E -i '' 's/https:\/\/img.shields.io\/travis\/([^/]+)\/([^/]+)\.svg/https:\/\/github.com\/\1\/\2\/workflows\/CI\/badge.svg?branch=master/g' README.rst
sed -E -i '' 's/https:\/\/img.shields.io\/travis\/([^/]+)\/([^/]+)\/master.svg/https:\/\/github.com\/\1\/\2\/workflows\/CI\/badge.svg?branch=master/g' README.rst
sed -E -i '' 's/https:\/\/travis-ci.org\/([^/]+)\/([^/]+)/https:\/\/github.com\/\1\/\2\/actions?workflow=CI/g' README.rst
subl -w tox.ini .github/workflows/main.yml .travis.yml
rm -rf .travis.yml
rm -rf requirements/py39*
subl -w requirements/compile.py
git add tox.ini .github/workflows/main.yml .travis.yml requirements README.rst
git commit -m "Move CI to GitHub Actions"
