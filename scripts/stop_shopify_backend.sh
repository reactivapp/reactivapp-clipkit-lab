#!/usr/bin/env bash

set -euo pipefail

PORT="${SHOPIFY_BACKEND_PORT:-8899}"
PID_FILE="${SHOPIFY_BACKEND_PID_FILE:-/tmp/shopify_backend.pid}"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${PID:-}" ]] && kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" >/dev/null 2>&1 || true
  fi
  rm -f "$PID_FILE"
fi

if lsof -t -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  kill "$(lsof -t -nP -iTCP:"$PORT" -sTCP:LISTEN)"
fi
