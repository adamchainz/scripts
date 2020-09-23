#!/bin/sh
set -ex

git switch -c python_m_pip
git grep --cached -Il '' | xargs sed -E -i '' -e 's/pip install/python -m pip install/g'
git add --all
git commit -m "Switch 'pip install' for 'python -m pip install'

As per [Brett Cannon's article](https://snarky.ca/why-you-should-use-python-m-pip/)."
git checkout .
pushupr
