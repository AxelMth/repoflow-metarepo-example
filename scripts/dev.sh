#!/usr/bin/env bash
set -euo pipefail

# Check that child repos have been synced
for dir in apps/web apps/api apps/shared; do
  if [ ! -d "$dir" ]; then
    echo "Error: $dir not found. Run 'pnpm sync' first to clone the child repos."
    exit 1
  fi
done

echo "==> Starting API server in background..."
pnpm --filter @repoflow-example/api dev &
API_PID=$!

echo "==> Starting web dev server (Ctrl+C to stop both)..."

# Clean up API process on exit
cleanup() {
  echo ""
  echo "==> Stopping API server (PID $API_PID)..."
  kill "$API_PID" 2>/dev/null || true
  wait "$API_PID" 2>/dev/null || true
  echo "==> Done."
}
trap cleanup EXIT INT TERM

pnpm --filter @repoflow-example/web dev
