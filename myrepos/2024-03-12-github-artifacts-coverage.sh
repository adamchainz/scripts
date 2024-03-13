#!/bin/sh
# shellcheck disable=SC2016
set -eux

rg -q actions/upload-artifact@v3 .github/workflows/main.yml

git diff --exit-code
git checkout main
git pull

sd -s -- \
    'uses: actions/upload-artifact@v3' \
    'uses: actions/upload-artifact@v4' \
    .github/workflows/main.yml

sd -s -- \
    'uses: actions/upload-artifact@v4
      with:
        name: coverage-data
        path: '"'"'.coverage.*'"'" \
    'uses: actions/upload-artifact@v4
      with:
        name: coverage-data-${{ matrix.python-version }}
        path: '"'"'${{ github.workspace }}/.coverage.*'"'" \
    .github/workflows/main.yml

sd -s -- \
    'uses: actions/download-artifact@v3
        with:
          name: coverage-data' \
    'uses: actions/download-artifact@v4
        with:
          path: ${{ github.workspace }}
          pattern: coverage-data-*
          merge-multiple: true' \
    .github/workflows/main.yml

git commit -am "Upgrade GitHub Actions artifact actions

Thanks to Mark Walker for the required changes to the coverage workflow."
git push
