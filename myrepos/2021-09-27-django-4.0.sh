#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

sd --string-mode 'Django 2.2 to 3.2 supported.' 'Django 2.2 to 4.0 supported.' README.rst

sd -f m '(=======
History
=======)' "\$1

* Support Django 4.0." HISTORY.rst

sd --string-mode 'Framework :: Django :: 3.2' 'Framework :: Django :: 3.2
    Framework :: Django :: 4.0' setup.cfg

for minor in 8 9; do

sd --string-mode 'py3'$minor'-django{22,30,31,32}' 'py3'$minor'-django{22,30,31,32,40}' tox.ini

sd --string-mode \
'[testenv:py3'$minor'-django32]
deps = -rrequirements/py3'$minor'-django32.txt' \
'[testenv:py3'$minor'-django32]
deps = -rrequirements/py3'$minor'-django32.txt

[testenv:py3'$minor'-django40]
deps = -rrequirements/py3'$minor'-django40.txt' \
tox.ini

sd --string-mode \
'    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py3'$minor'-django32.txt",
        ],
        check=True,
        capture_output=True,
    )' \
'    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py3'$minor'-django32.txt",
        ],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        [
            "python3.'$minor'",
            *common_args,
            "-P",
            "Django>=4.0a1,<4.1",
            "-o",
            "py3'$minor'-django40.txt",
        ],
        check=True,
        capture_output=True,
    )' requirements/compile.py

done

requirements/compile.py

git add README.rst HISTORY.rst setup.cfg tox.ini requirements
git switch -c django_4.0
git commit -m "Support Django 4.0"

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
