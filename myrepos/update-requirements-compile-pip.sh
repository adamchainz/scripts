#!/bin/sh
set -e

git switch -c requirements_compile_pip
# shellcheck disable=SC2016
sd '^( +)(os.environ\["CUSTOM_COMPILE_COMMAND.*)$' '$1$2
${1}os.environ.pop("PIP_REQUIRE_VIRTUALENV")' requirements/compile.py
./requirements/compile.py
git add requirements
git commit -m "Unset PIP_REQUIRE_VIRTUALENV in requirements/compile.py"
gh pr create --fill
gh pr view --web
