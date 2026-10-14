#!/usr/bin/env bash
set -euo pipefail

id=$(gh pr view --json closingIssuesReferences --jq '.closingIssuesReferences[0].id // empty')
[ -n "$id" ] || { echo "PR closes no issue"; read -r; exit 1; }
url=$(gh api graphql -f id="$id" -f query='query($id: ID!) { node(id: $id) { ... on Issue { url parent { url } } } }' \
  --jq '.data.node.parent.url // .data.node.url')
"${BROWSER:-xdg-open}" "$url"
