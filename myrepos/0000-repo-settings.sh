#!/bin/sh
set -eu

gh api 'repos/{owner}/{repo}' \
    --method PATCH \
    --silent \
    --field allow_auto_merge=true \
    --field allow_merge_commit=false \
    --field allow_rebase_merge=false \
    --field allow_squash_merge=true \
    --field delete_branch_on_merge=true \
    --field has_issues=true \
    --field has_projects=false \
    --field has_wiki=false \
    --field squash_merge_commit_message=PR_BODY \
    --field squash_merge_commit_title=PR_TITLE
