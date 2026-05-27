#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

# If commit titled "Improve GitHub Actions workflow" already exists, assume it's been merged and stop
if git log --grep='Improve GitHub Actions workflow' --max-count=1 --oneline 2>/dev/null | grep -q .; then
    echo "Commit already merged, stopping."
    exit 0
fi

# Fix multiple things using ruamel.yaml to preserve formatting and comments
# See inline comments
uvx --with ruamel.yaml python -c '
import sys, re
from ruamel.yaml import YAML
yaml = YAML()
yaml.preserve_quotes = True
yaml.width = float("inf")
path = sys.argv[1]
with open(path) as f:
    data = yaml.load(f)
for job_name, job in data.get("jobs", {}).items():
    # Remove unnecessary ${{ }} wrapping in if conditions
    if "if" in job and isinstance(job["if"], str):
        m = re.fullmatch(r"\$\{\{\s*(.*?)\s*\}\}", job["if"])
        if m:
            job["if"] = m.group(1)
    # Always run coverage job, allows failure
    if job_name == "coverage" and "if" not in job:
        keys = list(job.keys())
        job.insert(keys.index("steps") if "steps" in keys else len(keys), "if", "always()")
    for step in (job.get("steps") or []):
        if "if" in step and isinstance(step["if"], str):
            m = re.fullmatch(r"\$\{\{\s*(.*?)\s*\}\}", step["if"])
            if m:
                step["if"] = m.group(1)
        uses = str(step.get("uses", ""))
        # Disable actions/checkout credentials persistence (https://docs.zizmor.sh/audits/#artipacked)
        if uses.startswith("actions/checkout@"):
            if "with" not in step:
                step["with"] = {}
            step["with"]["persist-credentials"] = False
        # Disable uv caching in build/release jobs (https://docs.zizmor.sh/audits/#cache-poisoning)
        if job_name in ("build", "release") and uses.startswith("astral-sh/setup-uv"):
            if "with" not in step:
                step["with"] = {}
            step["with"]["enable-cache"] = False
from io import StringIO
buf = StringIO()
yaml.dump(data, buf)
text = re.sub(r"([ \t]+uses: [^\n]+)\n\n([ \t]+with:)", r"\1\n\2", buf.getvalue())
text = re.sub(r"((?:persist-credentials|enable-cache): false)\n([ \t]+-)", r"\1\n\n\2", text)
with open(path, "w") as f:
    f.write(text)
' .github/workflows/main.yml

# David Lord’s tool for pinning GitHub Actions to specific hashes
# https://gha-update.readthedocs.io/en/latest/
GITHUB_TOKEN=$(gh auth token) uvx gha-update

git switch -c improve_gha
git add .github/workflows/main.yml
git rm .github/dependabot.yml  # moving to manual gha-update runs from now on
git commit -m "Improve GitHub Actions workflow

Tidy up some problematic patterns, including some found with [zizmor](https://docs.zizmor.sh/), and use [gha-update](https://gha-update.readthedocs.io/en/latest/) to pin GitHub Actions to specific hashes."

git push && gh pr create --fill && sleep 1 && gh pr merge --squash --delete-branch --auto
