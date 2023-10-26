#!/bin/sh
# shellcheck disable=SC2016
set -eux

git diff --exit-code
git checkout main
git pull

# move flake8 config to tox.ini
# it can leave in .flake8, setup.cfg, or tox.ini
# use tox.ini for one less file
echo >> tox.ini
rg -U '(?s)\[flake8.*?^($|\[)' setup.cfg >> tox.ini
sd -f m '(?s)\[flake8.*?^($|\[)' '' setup.cfg

# drop flake8-typing-imports
# it reads the Python version from setup.cfg or requires an extra option
# but it provides no value from Python 3.8+ as there aren’t any typing
# incompatibilities in those patch releases
sd ' +- flake8-typing-imports\n' '' .pre-commit-config.yaml

# coverage config
# rebuild the config from scratch in pyproject.toml
# thankfully all projects use standard config, I think
if rg -q 'coverage' requirements/requirements.in
then
    sd -s 'coverage' 'coverage[toml]' requirements/requirements.in
    requirements/compile.py
    srcname="$(git ls-files 'src/*' | head -n 1 | sd 'src/(.*?)/.*' '$1')"
    echo "
[tool.coverage.run]
branch = true
parallel = true
source = [
    \"$srcname\",
    \"tests\",
]

[tool.coverage.paths]
source = [
    \"src\",
    \".tox/**/site-packages\",
]

[tool.coverage.report]
show_missing = true" >> pyproject.toml
    sd -f m '(?s)\[coverage.*?\n$' '' setup.cfg
fi

# setup.cfg
# Add repository URL - setup-to-pyproject doesn't convert this
sd '(?sm)url = (.*?)\n(.*?project_urls =)' '$2\n    Repository = $1' setup.cfg
# drop social urls
sd ' *Mastodon =.*?$' '' setup.cfg
sd ' *Twitter =.*?$' '' setup.cfg
# remoce existing build-system table as setup-to-pyproject regenerates it
sd -f s '\[build.*?\n\[' '[' pyproject.toml
# run setup-to-pyproject to add to pyproject.toml
mv pyproject.toml pyproject.toml.bak
setup-to-pyproject | tail -n +2 > pyproject.toml
echo >> pyproject.toml
cat pyproject.toml.bak >> pyproject.toml
rm -rf pyproject.toml.bak
# remove setup.cfg
rm setup.cfg
# drop setup-cfg-fmt
sd -f s '(-) repo: https://github\.com/asottile/setup-cfg-fmt.*?\n-' '$1' .pre-commit-config.yaml

# reformat
pre-commit run pyproject-fmt --file pyproject.toml || true

git switch -c setuptools_pyproject_toml
git commit -am "Migrate setuptools to use pyproject.toml

Support is no longer in beta since setuptools 68.1.0: https://setuptools.pypa.io/en/latest/history.html#v68-1-0

Migrated using https://github.com/diazona/setuptools-pyproject-migration, https://github.com/tox-dev/pyproject-fmt, and a bunch of regexes."

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web

