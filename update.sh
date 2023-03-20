#!/usr/bin/env bash

GITHUB_TOKEN="${GITHUB_TOKEN?Environment variable has to be set.}"

PROJECT_NAME="themix-gui"

read -d ¬ -r QUERY <<¬¬¬
{
  repository(owner: "themix-project", name: "${PROJECT_NAME}") {
    refs(last: 1, refPrefix: "refs/tags/") {
      nodes {
        target {
          repository { url }
          ... on Tag {
            name
            target {
              ... on Commit {
                oid
                submodules(first: 100) {
                  totalCount
                  nodes { gitUrl path subprojectCommitOid }
                }}}}}}}}}
¬
¬¬¬

read -d ¬ -r PARSE <<¬¬¬
  .data.repository.refs.nodes[0].target
  | [
    "${PROJECT_NAME}@\(.name) \(.repository.url).git \(.target.oid)"
  ] + [
    .target.submodules.nodes[]
    | "\(.path)  \(.gitUrl) \(.subprojectCommitOid)"
  ]
  | .[]
¬
¬¬¬

function github_query() {
    curl -s -L \
         -H 'Content-Type: application/json' \
         -H "Authorization: bearer ${GITHUB_TOKEN}" \
         -X POST -d @<(printf "%s" "{\"query\": \"${QUERY//\"/\\\"}\"}") \
         https://api.github.com/graphql
}

function prefetch_print_json() {
  echo "{"
  while read -r name url rev ; do
      echo "prefetch ${name} ${url}" >&2
      if [[ "${name}" =~ ^${PROJECT_NAME}@ ]] ; then
          printf '"version": "%s"\n' "${name#*@}"
          printf ',"%s": ' "${PROJECT_NAME}"
          nix-prefetch-git --url "$url" --rev "$rev" --quiet
      else
          printf ',"%s": ' "${name}"
          nix-prefetch-git --url "$url" --rev "$rev" --fetch-submodules --quiet
      fi
  done
  echo "}"
}

github_query | jq -r "${PARSE}" | prefetch_print_json | jq '.' | tee ./sources.json
