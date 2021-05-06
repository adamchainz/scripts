#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

sd --string-mode ' 3.9' ' 3.9
        - 3.10-dev' .github/workflows/main.yml
sd --string-mode 'Programming Language :: Python :: 3.9' 'Programming Language :: Python :: 3.9
    Programming Language :: Python :: 3.10' setup.cfg
sd -f m '(=======
History
=======)' "\$1

* Support Python 3.10." HISTORY.rst
sd --string-mode 'Python 3.6 to 3.9 supported.' 'Python 3.6 to 3.10 supported.' README.rst
sd --string-mode 'py{36,37,38,39}' 'py{36,37,38,39,310}' tox.ini
sd --string-mode 'py39-django{22,30,31,32}' 'py39-django{22,30,31,32}
    py310-django32' tox.ini
sd --string-mode '[testenv:py39]
deps = -rrequirements/py39.txt' '[testenv:py39]
deps = -rrequirements/py39.txt

[testenv:py310]
deps = -rrequirements/py310.txt' tox.ini
sd --string-mode '[testenv:py39-django32]
deps = -rrequirements/py39-django32.txt' '[testenv:py39-django32]
deps = -rrequirements/py39-django32.txt

[testenv:py310-django32]
deps = -rrequirements/py310-django32.txt' tox.ini
sd --string-mode 'subprocess.run(
        ["python3.9", *common_args, "-o", "py39.txt"],
        check=True,
    )' 'subprocess.run(
        ["python3.9", *common_args, "-o", "py39.txt"],
        check=True,
    )
    subprocess.run(
        ["python3.10", *common_args, "-o", "py310.txt"],
        check=True,
    )' requirements/compile.py
sd --string-mode 'subprocess.run(
        [
            "python3.9",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py39-django32.txt",
        ],
        check=True,
    )' 'subprocess.run(
        [
            "python3.9",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py38-django32.txt",
        ],
        check=True,
    )
    subprocess.run(
        [
            "python3.10",
            *common_args,
            "-P",
            "Django>=3.2a1,<3.3",
            "-o",
            "py310-django32.txt",
        ],
        check=True,
    )' requirements/compile.py

subl -w tox.ini requirements/compile.py README.rst

requirements/compile.py

git add .github/workflows/main.yml setup.cfg HISTORY.rst tox.ini requirements/ README.rst
git switch -c python_3.10
git commit -m "Support Python 3.10."

echo "Check below search results for more to change..."
rg --pretty '3\b.*\b(9|10)\b'
