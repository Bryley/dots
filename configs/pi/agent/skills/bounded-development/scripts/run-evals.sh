#!/usr/bin/env bash
# Run the BD skill evals.
# Usage: ./run-evals.sh [evalt args...]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EVALS_DIR="$SKILL_DIR/evals"

echo "Running BD skill evals from $EVALS_DIR"
cd "$EVALS_DIR"
exec evalt bd.eval.yaml "$@"
