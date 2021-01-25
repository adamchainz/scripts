#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

sd --string-mode 'Django 2.2 to 3.1 supported.' 'Django 2.2 to 3.2 supported.' README.rst

sd -f m '(=======
History
=======)' "\$1

* Support Django 3.2." HISTORY.rst

sd --string-mode 'Framework :: Django :: 3.1' 'Framework :: Django :: 3.1
    Framework :: Django :: 3.2' setup.cfg

for minor in 6 7 8 9; do

sd --string-mode 'py3'$minor'-django{22,30,31}' 'py3'$minor'-django{22,30,31,32}' tox.ini

sd --string-mode \
'[testenv:py3'$minor'-django31]
deps = -rrequirements/py3'$minor'-django31.txt' \
'[testenv:py3'$minor'-django31]
deps = -rrequirements/py3'$minor'-django31.txt

[testenv:py3'$minor'-django32]
deps = -rrequirements/py3'$minor'-django32.txt' \
tox.ini

sd --string-mode \
'    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=3.1a1,<3.2",
            "-o",
            "py3'$minor'-django31.txt",
        ],
        check=True,
    )' \
'    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=3.1a1,<3.2",
            "-o",
            "py3'$minor'-django31.txt",
        ],
        check=True,
    )
    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py3'$minor'-django32.txt",
        ],
        check=True,
    )' requirements/compile.py

done

requirements/compile.py

git add README.rst HISTORY.rst setup.cfg tox.ini requirements
git switch -c django_3.2
git commit -m "Support Django 3.2"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
