#!/bin/sh
set -eu

git diff --exit-code
git checkout main
git pull

sd --string-mode 'py310-django{40}' 'py310-django{32,40}' tox.ini
sd --string-mode '[testenv:py310-django40]' '[testenv:py310-django32]
deps = -rrequirements/py310-django32.txt

[testenv:py310-django40]' tox.ini

sd --string-mode 'subprocess.run(
        [
            "python3.10",
            *common_args,
            "-P",
            "Django>=4.0a1,<4.1",
            "-o",
            "py310-django40.txt",
        ],
        check=True,
        capture_output=True,
    )' 'subprocess.run(
        [
            "python3.10",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py310-django32.txt",
        ],
        check=True,
        capture_output=True,
    )
    subprocess.run(
        [
            "python3.10",
            *common_args,
            "-P",
            "Django>=4.0a1,<4.1",
            "-o",
            "py310-django40.txt",
        ],
        check=True,
        capture_output=True,
    )' requirements/compile.py

subl -w tox.ini requirements/compile.py

requirements/compile.py

git add tox.ini requirements/ README.rst
git switch -c django_3.2_python_3.10
git commit -m "Test Django 3.2 on Python 3.10."

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
