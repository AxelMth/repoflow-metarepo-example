#!/usr/bin/env bash
# wait-for-workflows.sh
#
# Poll the GitHub API until each child repo's deployment workflow (triggered by
# a tag push) completes. Exit 0 on success, 1 if any run failed or timed out.
#
# Input: JSON array as $1. Entries look like:
#   [{ "repo": "owner/api", "tag": "v1.3.0", "workflow": "deploy-preprod.yml",
#      "commitSha": "abc123", "tagPushedAt": "2026-04-21T07:20:00Z" }]
#
# Requires: gh CLI (authenticated via GITHUB_TOKEN or GIT_PAT) + jq

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 '<json-array>'" >&2
  exit 2
fi

INPUT="$1"

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI not found" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq not found" >&2
  exit 2
fi

# 20-minute overall budget, poll every 15s
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-1200}
POLL_INTERVAL=${POLL_INTERVAL:-15}
deadline=$(( $(date +%s) + TIMEOUT_SECONDS ))

# Parse the JSON array into a list of pipe-separated rows
mapfile -t ENTRIES < <(jq -rc '.[] | [.repo, .tag, .workflow, .commitSha, .tagPushedAt] | @tsv' <<<"$INPUT")

if (( ${#ENTRIES[@]} == 0 )); then
  echo "nothing to wait for"
  exit 0
fi

# State arrays, indexed by entry number
declare -a STATUS
for i in "${!ENTRIES[@]}"; do STATUS[$i]="pending"; done

fail=0

while :; do
  all_done=1
  for i in "${!ENTRIES[@]}"; do
    current="${STATUS[$i]}"
    if [[ "$current" == success || "$current" == failure ]]; then continue; fi

    IFS=$'\t' read -r repo tag workflow commit pushed_at <<<"${ENTRIES[$i]}"

    # Find the latest run for this workflow file that was created after the tag push
    # and whose head_sha matches. We also filter by event=push (tag events are 'push').
    run_json=$(gh api -X GET "repos/${repo}/actions/workflows/${workflow}/runs" \
      -f "per_page=20" -f "event=push" 2>/dev/null \
      | jq -c --arg sha "$commit" --arg since "$pushed_at" '
          .workflow_runs
          | map(select(.head_sha == $sha and .created_at >= $since))
          | sort_by(.created_at) | last // empty') || run_json=""

    if [[ -z "$run_json" || "$run_json" == "null" ]]; then
      STATUS[$i]="queued"
      echo "⏳ ${repo} (${tag})... waiting for run"
      all_done=0
      continue
    fi

    status=$(jq -r '.status' <<<"$run_json")
    conclusion=$(jq -r '.conclusion // ""' <<<"$run_json")
    url=$(jq -r '.html_url' <<<"$run_json")

    if [[ "$status" != "completed" ]]; then
      STATUS[$i]="running"
      echo "⏳ ${repo} (${tag})... ${status}"
      all_done=0
      continue
    fi

    if [[ "$conclusion" == "success" ]]; then
      STATUS[$i]="success"
      echo "✅ ${repo} (${tag}) deployed"
    else
      STATUS[$i]="failure"
      fail=1
      echo "❌ ${repo} (${tag}) ${conclusion} — ${url}"
    fi
  done

  (( all_done )) && break

  if (( $(date +%s) >= deadline )); then
    echo "::error::timed out after ${TIMEOUT_SECONDS}s waiting for deployments" >&2
    for i in "${!ENTRIES[@]}"; do
      if [[ "${STATUS[$i]}" != "success" && "${STATUS[$i]}" != "failure" ]]; then
        IFS=$'\t' read -r repo tag _ _ _ <<<"${ENTRIES[$i]}"
        echo "⏱  ${repo} (${tag}) still ${STATUS[$i]}"
      fi
    done
    exit 1
  fi

  sleep "$POLL_INTERVAL"
done

exit "$fail"
