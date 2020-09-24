#!/bin/sh
set -e

git diff --exit-code
git checkout master
git pull

rm -rf .editorconfig || true

echo '# http://editorconfig.org

root = true

[*]
indent_style = space
indent_size = 4
trim_trailing_whitespace = true
insert_final_newline = true
charset = utf-8
end_of_line = lf

[*.{css,html,js,yaml,yml}]
indent_size = 2

[Makefile]
indent_style = tab' > .editorconfig

git add .editorconfig
git switch -c editorconfig
git commit -m 'Make editorconfig consistent with other projects'

git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
gh pr create --fill
gh pr view --web

