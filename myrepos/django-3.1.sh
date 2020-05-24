#!/bin/sh
set -e

git switch -c django_3.1
sed -E -i '' -e 's/    Framework :: Django :: 3.0/    Framework :: Django :: 3.0\
    Framework :: Django :: 3.1/g' setup.cfg
subl -w setup.cfg requirements/compile.py tox.ini HISTORY.rst
./requirements/compile.py
git add --all
git commit -m "Test with Django 3.1"
pushupr
