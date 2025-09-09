#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

sd -s -- \
$'    - name: Install dependencies
      run: uv pip install --system tox tox-uv

    - name: Run tox targets for ${{ matrix.python-version }}
      run: tox run -f py$(echo ${{ matrix.python-version }} | tr -d .)' \
$'    - name: Run tox targets for ${{ matrix.python-version }}
      run: uvx --with tox-uv tox run -f py$(echo ${{ matrix.python-version }} | tr -d .)' \
.github/workflows/main.yml

if git diff --quiet --exit-code; then
  echo "No changes to commit."
  exit 0
fi

git switch -c uvx-tox
git commit -m "Use uvx to run tox on GitHub Actions" .github/workflows/main.yml
git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
