#!/bin/sh
set -eux

git diff --exit-code
git switch main
git pull

if [ ! -f pyproject.toml ]; then
  echo "Skipping project without pyproject.toml."
  exit
fi

if ! rg -q coverage pyproject.toml; then
  echo "Skipping project not using Coverage."
  exit
fi

git apply << 'EOF'
diff --git ./pyproject.toml ./pyproject.toml
index 0243557..51d3062 100644
--- ./pyproject.toml
+++ ./pyproject.toml
@@ -120,2 +120,3 @@ ini_options.xfail_strict = true
 run.branch = true
+run.data_file = ".coverage/cov"
 run.parallel = true
@@ -130,2 +131,4 @@ paths.source = [
 report.show_missing = true
+report.skip_covered = true
+report.skip_empty = true

# EOF

sd -s '${{ github.workspace }}/.coverage.*' '${{ github.workspace }}/.coverage/*' .github/workflows/main.yml

sd -s 'path: ${{ github.workspace }}' 'path: .coverage' .github/workflows/main.yml

git commit -m "Fix GitHub Actions workflow" .github/workflows/main.yml && git push

git add --update .
git switch -c improve_coverage_configruation
git commit -m "Improve Coverage.py configuration

# Hide data files within a directory to avoid cluttering the repository root, and minimize reports."

git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
