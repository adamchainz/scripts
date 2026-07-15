#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

if git log --grep='Fail coverage GHA job when tests fail' --max-count=1 --oneline 2>/dev/null | grep -q .; then
    echo "Commit already merged, stopping."
    exit 0
fi

workflow_files=(.github/workflows/*.yml(N) .github/workflows/*.yaml(N))
if (( ${#workflow_files} == 0 )); then
    echo "No GitHub Actions workflow files found."
    exit 0
fi

uvx --with ruamel.yaml python -c '
import re
import sys
from io import StringIO

from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap

check_step_name = "Check all test jobs passed"


def needs_tests(needs):
    if isinstance(needs, str):
        return needs == "tests"
    return "tests" in (needs or [])


yaml = YAML()
yaml.preserve_quotes = True
yaml.width = float("inf")

for path in sys.argv[1:]:
    with open(path) as f:
        data = yaml.load(f)

    job = (data or {}).get("jobs", {}).get("coverage")
    if not isinstance(job, dict) or not needs_tests(job.get("needs")):
        continue

    steps = job.get("steps")
    if not steps or any(step.get("name") == check_step_name for step in steps if isinstance(step, dict)):
        continue

    if "if" not in job:
        keys = list(job.keys())
        job.insert(keys.index("steps") if "steps" in keys else len(keys), "if", "always()")

    check_step = CommentedMap()
    check_step["name"] = check_step_name
    check_step["if"] = "needs.tests.result != '"'"'success'"'"'"
    check_step["run"] = "exit 1"
    steps.insert(0, check_step)

    buf = StringIO()
    yaml.dump(data, buf)
    text = re.sub(r"(run: exit 1)\n([ \t]+-)", r"\1\n\n\2", buf.getvalue())
    with open(path, "w") as f:
        f.write(text)
' "${workflow_files[@]}"

if git diff --quiet -- .github/workflows; then
    echo "No coverage jobs to update."
    exit 0
fi

git switch -c fail_coverage_job_when_tests_fail
git add "${workflow_files[@]}"
git commit -m "Fail coverage GHA job when tests fail

Add an explicit guard to ensure that the coverage job fails if the tests fail, so that if only some tests fail but coverage remains 100%, the required coverage job does not complete."

git push && gh pr create --fill && sleep 1 && gh pr merge --squash --delete-branch --auto
