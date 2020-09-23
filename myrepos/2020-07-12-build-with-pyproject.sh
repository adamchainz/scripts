#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd 'exclude pyproject\.toml' 'include pyproject.toml' MANIFEST.in

echo '[build-system]
requires = ["setuptools >= 40.6.0", "wheel"]
build-backend = "setuptools.build_meta"
' > pyproject.toml2
[ -f pyproject.toml ] && cat pyproject.toml >> pyproject.toml2
mv pyproject.toml2 pyproject.toml

sd '(\[tox\])' '[tox]
isolated_build = True' tox.ini

git add MANIFEST.in pyproject.toml setup.cfg tox.ini

git switch -c build_with_pyproject
git commit -m "Build with pep517 and pyproject.toml"

PIP_REQUIRE_VIRTUALENV='' python -m pep517.build .

gh pr create --fill
gh pr view --web
