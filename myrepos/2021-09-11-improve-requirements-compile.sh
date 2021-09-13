#!/bin/sh
set -e

git diff --exit-code
git checkout main
git pull

# shellcheck disable=SC2016
sd '(common_args = \[.*?)\]' '$1, "--allow-unsafe"]' requirements/compile.py
sd 'check=True,' 'check=True, capture_output=True,' requirements/compile.py
pre-commit run black --files requirements/compile.py || true
requirements/compile.py || true

git add requirements/
git switch -c improve_requirements_compile
# shellcheck disable=SC2016
git commit -m 'Improve requirements/compile.py

* Adopt `--allow-unsafe` early
* Capture output to avoid terminal spam.
'

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web
