#!/bin/zsh
set -eu

git diff --exit-code
git switch main
git pull

old_ubuntu='ubuntu-2[024]\.04'

# (N) = empty list if no match, (.) = regular files only
files=(.github/workflows/*.(yml|yaml)(N.) .readthedocs.(yml|yaml)(N.))
if (( ! $#files )); then
    echo "No GitHub Actions or Read the Docs config found."
    exit 0
fi

# rg exits 1 for no matches, which is fine, but 2 for errors, which should stop us
# (f) splits the output into an array on newlines
matching=(${(f)"$(rg -l $old_ubuntu $files || (( $? == 1 )))"})
if (( ! $#matching )); then
    echo "No old Ubuntu versions found, nothing to migrate."
    exit 0
fi

git switch -c ubuntu_26.04

# GitHub Actions: runs-on, including ubuntu-24.04-arm and expressions
# Read the Docs: build.os
sd $old_ubuntu ubuntu-26.04 $matching

git add $matching
git commit -m "Upgrade to Ubuntu 26.04"

git push
gh pr create --fill
sleep 1
gh pr merge --squash --delete-branch --auto
