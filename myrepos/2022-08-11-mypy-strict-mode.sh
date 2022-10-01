#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

sd -s 'show_error_codes = true' 'show_error_codes = true
strict = true' pyproject.toml

sd -s 'check_untyped_defs = true
' '' pyproject.toml
sd -s 'disallow_any_generics = true
' '' pyproject.toml
sd -s 'disallow_incomplete_defs = true
' '' pyproject.toml
sd -s 'disallow_subclassing_any = true
' '' pyproject.toml
sd -s 'disallow_untyped_calls = true
' '' pyproject.toml
sd -s 'disallow_untyped_decorators = true
' '' pyproject.toml
sd -s 'disallow_untyped_defs = true
' '' pyproject.toml
sd -s 'no_implicit_optional = true
' '' pyproject.toml
sd -s 'no_implicit_reexport = true
' '' pyproject.toml
sd -s 'strict_concatenate = true
' '' pyproject.toml
sd -s 'strict_equality = true
' '' pyproject.toml
sd -s 'warn_redundant_casts = true
' '' pyproject.toml
sd -s 'warn_return_any = true
' '' pyproject.toml
sd -s 'warn_unused_ignores = true
' '' pyproject.toml
sd -s 'warn_unused_configs = true
' '' pyproject.toml

if rg -q django tox.ini; then
  sd -s 'id: mypy' 'id: mypy
    additional_dependencies:
    - django-stubs==1.12.0' .pre-commit-config.yaml
fi

pre-commit run mypy --all
