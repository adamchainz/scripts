#!/bin/sh
set -eux

git diff --exit-code
git switch main
git pull

if [ ! -f pyproject.toml ]; then
    echo "pyproject.toml not found"
    exit 1
fi

if ! rg -q pytest pyproject.toml; then
    echo "pytest not found in pyproject.toml"
    exit 1
fi

if ! rg -q ini_options pyproject.toml; then
    echo "ini_options not found in pyproject.toml"
    exit 1
fi

uvx --with tomlkit python << 'PYTHON'
import tomlkit
import sys

with open("pyproject.toml") as f:
    doc = tomlkit.load(f)

# Set pytest dep to >=9
for group_name, deps in doc.get("dependency-groups", {}).items():
    for i, dep in enumerate(deps):
        if isinstance(dep, str) and dep == "pytest":
            deps[i] = "pytest>=9"

# Set tool.pytest.strict = true
pytest_section = doc["tool"]["pytest"]
pytest_section["strict"] = True

# Drop ini_options.xfail_strict
ini_options = pytest_section.get("ini_options", {})
if "xfail_strict" in ini_options:
    del ini_options["xfail_strict"]

# Move django_find_project from ini_options to main options
if "django_find_project" in ini_options:
    pytest_section["django_find_project"] = ini_options["django_find_project"]
    del ini_options["django_find_project"]

# Parse and handle addopts
if "addopts" in ini_options:
    raw = ini_options["addopts"]
    items = [item.strip() for item in raw.split() if item.strip()]

    expected = {"--strict-config", "--strict-markers"}
    ds_prefix = "--ds="
    ds_value = None
    remaining = []

    for item in items:
        if item in expected:
            continue
        elif item.startswith(ds_prefix):
            ds_value = item[len(ds_prefix):]
        else:
            remaining.append(item)

    if remaining:
        pytest_section["addopts"] = remaining

    del ini_options["addopts"]

    if ds_value:
        pytest_section["DJANGO_SETTINGS_MODULE"] = ds_value


# Check ini_options is now empty and error or drop as appropriate
if ini_options:
    print("unknown ini_options:", ini_options, file=sys.stderr)
    sys.exit(1)
del pytest_section["ini_options"]

with open("pyproject.toml", "w") as f:
    tomlkit.dump(doc, f)
PYTHON

uv lock

pre-commit run pyproject-fmt --all-files >/dev/null 2>/dev/null || true

git add --update pyproject.toml uv.lock
git switch -c upgrade_pytest_configuration
git commit -m "Upgrade pytest configuration

Use the new proper TOML support [added in pytest 9](https://docs.pytest.org/en/stable/changelog.html#pytest-9-0-0-2025-11-05)."

git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
