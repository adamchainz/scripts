#!/bin/sh
set -e

repository_id=$(gh api graphql -F owner=':owner' -F name=':repo' -f query='
query ($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id
  }
}' | jq .data.repository.id -r)

gh api graphql -F repositoryId=$repository_id -f query='mutation disableWiki($repositoryId: String!) {
  updateRepository(input: {
    repositoryId: $repositoryId,
    hasWikiEnabled: false,
    hasProjectsEnabled: false
  }) {
    repository{
      nameWithOwner
      hasWikiEnabled
      hasProjectsEnabled
    }
  }
}'
