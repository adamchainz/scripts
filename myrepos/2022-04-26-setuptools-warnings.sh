#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

# Delete a bunch of lines from setuptools config that aren't necessary and
# trigger warnings (which I hadn't seen before)

# /.../django-minify-html/.tox/.package/lib/python3.10/site-packages/setuptools/config/setupcfg.py:458: DeprecationWarning: The license_file parameter is deprecated, use license_files instead.
#   warnings.warn(msg, warning_class)
# warning: no previously-included files matching '*.py[cod]' found anywhere in distribution
# no previously-included directories found matching '__pycache__'
# no previously-included directories found matching 'requirements'
# no previously-included directories found matching 'tests'
# warning: no previously-included files found matching '.editorconfig'
# warning: no previously-included files found matching '.pre-commit-config.yaml'
# warning: no previously-included files found matching 'tox.ini'

sd -s 'license_file = LICENSE
' '' setup.cfg
sd -s 'global-exclude *.py[cod]
' '' MANIFEST.in
sd -s 'prune __pycache__
' '' MANIFEST.in
sd -s 'prune requirements
' '' MANIFEST.in
sd -s 'prune tests
' '' MANIFEST.in
sd -s 'exclude .editorconfig
' '' MANIFEST.in
sd -s 'exclude .pre-commit-config.yaml
' '' MANIFEST.in
sd -s 'exclude tox.ini
' '' MANIFEST.in

# Also remove check-manifest, which is the cause of these warnings, as it
# requires absolute coverage in MANIFEST.in even though setuptools ignores many
# warnings by default.
# I think I'll be fine without it since isolated builds mean tests now use the
# package exactly as built and installed.

sd -s -- '- repo: https://github.com/mgedmin/check-manifest
  rev: "0.48"
  hooks:
  - id: check-manifest
    args: [--no-build-isolation]
' '' .pre-commit-config.yaml

git add setup.cfg MANIFEST.in .pre-commit-config.yaml

git switch -c setuptools_warnings
git commit -m "Tidy MANIFEST.in and remove check-manifest

Delete some unnecessary entries from MANIFEST.in which trigger warnings from setuptools, and remove check-manifest which requires these unnecessary entries. Should be fine without check-manifest as tox uses isolated builds now."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
