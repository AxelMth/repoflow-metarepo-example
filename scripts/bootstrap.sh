#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing orchestrator dependencies..."
pnpm install

echo "==> Syncing child repos..."
pnpm sync

echo "==> Installing child dependencies..."
pnpm -r install

echo "==> Building all packages..."
pnpm build

echo ""
echo "Bootstrap complete! Run 'pnpm dev' to start the dev servers."
