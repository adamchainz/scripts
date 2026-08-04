#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if [ ! -f pyproject.toml ]; then
    echo "pyproject.toml not found"
    exit 0
fi

if ! rg -q sphinx-build-compatibility pyproject.toml; then
    echo "sphinx-build-compatibility not installed, nothing to remove."
    exit 0
fi

repository_url=$(gh repo view --json url --jq .url)

uvx --with tomlkit python - "$repository_url" << 'PYTHON'
import re
import sys
from pathlib import Path

import tomlkit

repository_url = sys.argv[1]

with open("pyproject.toml") as f:
    doc = tomlkit.load(f)

# Drop the dependency

for deps in doc.get("dependency-groups", {}).values():
    for i, dep in reversed(list(enumerate(deps))):
        if isinstance(dep, str) and dep == "sphinx-build-compatibility":
            del deps[i]

# Drop the Git source pin, and any table it leaves empty

uv = doc.get("tool", {}).get("uv", {})
sources = uv.get("sources", {})
if "sphinx-build-compatibility" in sources:
    del sources["sphinx-build-compatibility"]
    if not sources:
        del uv["sources"]
    if not uv:
        del doc["tool"]["uv"]

with open("pyproject.toml", "w") as f:
    tomlkit.dump(doc, f)

conf_py = Path("docs/conf.py")
if conf_py.exists():
    text = conf_py.read_text()

    text = text.replace(
        'if os.environ.get("READTHEDOCS") == "True":\n'
        '    extensions.append("sphinx_build_compatibility.extension")\n',
        "",
    )
    if not re.search(r"\bos\.", text):
        text = text.replace("import os\n", "")

    # Furo built its “edit this page” links from the html_context variables that
    # only the extension populated. Configure its native options instead.
    if 'html_theme = "furo"' in text and "source_repository" not in text:
        options = (
            f'    "source_repository": "{repository_url}/",\n'
            '    "source_branch": "main",\n'
            '    "source_directory": "docs/",\n'
        )
        if "html_theme_options = {" in text:
            text = re.sub(
                r"(?ms)^(html_theme_options = \{.*?)^\}$",
                lambda match: match[1] + options + "}",
                text,
                count=1,
            )
        else:
            text = text.replace(
                'html_theme = "furo"\n',
                'html_theme = "furo"\nhtml_theme_options = {\n' + options + "}\n",
            )

    conf_py.write_text(text)
PYTHON

uv lock

pre-commit run --all-files >/dev/null 2>/dev/null || true

git add --update
git switch -c remove_sphinx_build_compatibility
git commit -m "Remove sphinx-build-compatibility

The extension is [explicitly a temporary workaround](https://github.com/readthedocs/sphinx-build-compatibility) for Read the Docs no longer injecting variables into Sphinx’s html_context. The only ones Furo used were those behind the “edit this page” links, which it supports natively through theme options."

git push
sleep 1
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
