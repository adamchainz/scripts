#!/bin/sh
set -eux

git diff --exit-code
git checkout main
git pull

sd -s \
'        cache: pip
        cache-dependency-path: '\''requirements/*.txt'\' \
'
    - name: Install uv
      uses: astral-sh/setup-uv@v1
      with:
        enable-cache: true' \
.github/workflows/main.yml

sd -s \
'      run: |
        python -m pip install --upgrade pip setuptools wheel
        python -m pip install --upgrade '\''tox>=4.0.0rc3'\' \
'      run: uv pip install --system tox tox-uv' \
.github/workflows/main.yml

if rg -q coverage .github/workflows/main.yml; then
  sd -s '      - name: Install dependencies
        run: python -m pip install --upgrade coverage[toml]' \
'      - name: Install uv
        uses: astral-sh/setup-uv@v1

      - name: Install dependencies
        run: uv pip install --system coverage[toml]' \
  .github/workflows/main.yml
fi

git switch -c gha_uv
git commit -m "Use uv on GitHub Actions

Gives a nice speed boost." .github/workflows/main.yml

git push
gh pr create --fill
sleep 1  # github sometimes slow
gh pr view --web
gh pr merge --squash --delete-branch --auto
