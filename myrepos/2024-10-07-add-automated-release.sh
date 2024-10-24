#!/bin/zsh
set -eu

git diff --exit-code
git checkout main
git pull

# Create or update the release environment
gh api --method PUT '/repos/{owner}/{repo}/environments/release'

# Set up trusted publisher on PyPI
owner=$(gh repo view --json owner -q .owner.login)
project=$(gh repo view --json name -q .name)
# Values to “paste by typing” into the form on PyPI
echo -n "$owner\t$project\tmain.yml\trelease" | pbcopy
open "https://pypi.org/manage/project/$project/settings/publishing/"
echo "Press enter to continue"
read -r

# Add to GitHub Actions workflow
sd '    - main' $'    - main
    tags:
    - \'**\'' .github/workflows/main.yml

if rg -q 'coverage:' .github/workflows/main.yml; then
    echo $'
  release:
    needs: [coverage]
    if: success() && startsWith(github.ref, \'refs/tags/\')
    runs-on: ubuntu-24.04
    environment: release

    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - uses: astral-sh/setup-uv@v3

      - name: Build
        run: uv build

      - uses: pypa/gh-action-pypi-publish@release/v1' >> .github/workflows/main.yml
else
    echo $'
  release:
    needs: [tests]
    if: success() && startsWith(github.ref, \'refs/tags/\')
    runs-on: ubuntu-24.04
    environment: release

    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - uses: astral-sh/setup-uv@v3

      - name: Build
        run: uv build

      - uses: pypa/gh-action-pypi-publish@release/v1' >> .github/workflows/main.yml
fi

git switch -c auto_release
git commit -m "Add automated release process" .github/workflows/main.yml

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
gh pr merge --squash --delete-branch --auto
