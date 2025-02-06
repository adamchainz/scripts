#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ -f .pre-commit-config.yaml ]; then
  sd -s \
'default_language_version:
  python: python3.12' \
'default_language_version:
  python: python3.13' \
.pre-commit-config.yaml
fi

if [ -f .github/workflows/main.yml ]; then
  sd -s \
$'  coverage:
    name: Coverage
    runs-on: ubuntu-24.04
    needs: tests
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: \'3.12\'' \
$'  coverage:
    name: Coverage
    runs-on: ubuntu-24.04
    needs: tests
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: \'3.13\'' \
.github/workflows/main.yml
fi

if [ -f .readthedocs.yaml ]; then
  sd -s 'python: "3.12"' 'python: "3.13"' .readthedocs.yaml
fi

if git diff --exit-code; then
  echo "No changes to commit"
  exit 0
fi

pre-commit run --all-files

git commit -am "Run pre-commit, coverage, and readthedocs on Python 3.13"
