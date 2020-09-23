#!/bin/sh
set -e

git switch -c django_drop_old
sed -E -i '' -e '/    Framework :: Django :: 2.0/d' setup.cfg
sed -E -i '' -e '/    Framework :: Django :: 2.1/d' setup.cfg
open "*.sublime-project"
# setup.cfg - update install_requires
# requirements/compile.py - drop compilation for removed versions
# tox.ini - drop testing of removed versions
# HISTORY.rst - add note "* Drop Django 2.0 and 2.1 support."
# README.rst - update supported versions
# Also grep whole repo for code dependent on django version
subl -w setup.cfg requirements/compile.py tox.ini HISTORY.rst README.rst
git rm requirements/*-django20.txt
git rm requirements/*-django21.txt
git add --all
git commit -m "Drop Django 2.0 and 2.1 support"
gh pr create --fill
gh pr view --web
