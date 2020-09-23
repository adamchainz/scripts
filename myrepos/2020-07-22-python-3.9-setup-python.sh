#!/bin/bash
set -e

git diff --exit-code
git checkout master
git pull

sd -- '- 3.9' '- 3.9-dev' .github/workflows/main.yml

cat << 'EOF' | git apply -
diff --git a/.github/workflows/main.yml b/.github/workflows/main.yml
index dff8c06..1e4079f 100644
--- a/.github/workflows/main.yml
+++ b/.github/workflows/main.yml
@@ -22,12 +22,7 @@ jobs:

     steps:
     - uses: actions/checkout@v2
-    - uses: actions/setup-python@v2
-      if: matrix.python-version != '3.9'
-      with:
-        python-version: ${{ matrix.python-version }}
-    - uses: deadsnakes/action@v1.0.0
-      if: matrix.python-version == '3.9'
+    - uses: actions/setup-python@v2.1.1
       with:
         python-version: ${{ matrix.python-version }}
     - uses: actions/cache@v2
EOF

git add .github/workflows/main.yml

git switch -c python_3.9_setup_python
git commit -m " GitHub actions use Python 3.9 from setup-python"

gh pr create --fill
gh pr view --web
