#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ ! -d "tests/requirements" ]; then
    echo "tests/requirements not found"
    exit 0
fi

# check uv_test_dependencies branch does not exist
if git show-ref --verify --quiet refs/heads/uv_test_dependencies; then
    echo "Branch uv_test_dependencies already exists"
    exit 0
fi

set +e
rg -q django tests/requirements/requirements.in; django=$?
set -e

dependency_groups=$'[dependency-groups]\ntest = [\n'
# append contents of tests/requirements.in
while IFS= read -r line; do
    dependency_groups+=$'  "'"${line//\"/'}"$'",\n'
done < tests/requirements/requirements.in
dependency_groups+=$']\n'
if [ "$django" -eq 0 ]; then
    dependency_groups+=\
$'django42 = [ "django>=4.2a1,<5; python_version>=\'3.8\'" ]
django50 = [ "django>=5.0a1,<5.1; python_version>=\'3.10\'" ]
django51 = [ "django>=5.1a1,<5.2; python_version>=\'3.10\'" ]
django52 = [ "django>=5.2a1,<6; python_version>=\'3.10\'" ]'
fi
dependency_groups+=$'\n'

sd -s '[tool.isort]' "$dependency_groups"$'\n[tool.isort]' pyproject.toml

if [ "$django" -eq 0 ]; then
    echo '[tool.uv]
conflicts = [
    [
    { group = "django42" },
    { group = "django50" },
    { group = "django51" },
    { group = "django52" },
    ],
]' >> pyproject.toml
fi

pre-commit run pyproject-fmt --file pyproject.toml >/dev/null 2>&1 || true

sd -s $'[testenv]\n' $'[testenv]\nrunner = uv-venv-lock-runner\n' tox.ini

sd -s 'deps =
    -r tests/requirements/{envname}.txt
' '' tox.ini

tox_dependency_groups=$'dependency_groups =
    test'
if [ "$django" -eq 0 ]; then
    tox_dependency_groups+=$'
    django42: django42
    django50: django50
    django51: django51
    django52: django52'
fi

sd -s $'[testenv]\n' $'[testenv]\n'"$tox_dependency_groups"$'\n' tox.ini

pre-commit run tox-ini-fmt --file tox.ini >/dev/null 2>&1 || true

uv lock --upgrade

git rm -r tests/requirements
git add pyproject.toml tox.ini uv.lock

git switch -c uv_test_dependencies
git commit -m "Move test dependencies to native uv"

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
gh pr merge --squash --delete-branch --auto

sleep 10
