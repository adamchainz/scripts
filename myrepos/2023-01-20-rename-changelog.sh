#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

git mv HISTORY.rst CHANGELOG.rst
sd -s '/blob/main/HISTORY.rst' '/blob/main/CHANGELOG.rst' setup.cfg
sd -s 'include HISTORY.rst' 'include CHANGELOG.rst' MANIFEST.in
echo "See $(rg -o 'http.*CHANGELOG.rst' setup.cfg)" > HISTORY.rst

git add HISTORY.rst
git commit -a -m "Rename HISTORY.rst to CHANGELOG.rst

The name HISTORY.rst was inherited from [cookiecutter-pypackage](https://github.com/audreyfeldroy/cookiecutter-pypackage). But it’s not-so-standard, most projects use CHANGELOG. Switching to that name to make it easier for users to spot."
