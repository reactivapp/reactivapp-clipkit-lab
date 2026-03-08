#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

HOST="${SHOPIFY_BACKEND_HOST:-127.0.0.1}"
PORT="${SHOPIFY_BACKEND_PORT:-8899}"
PID_FILE="${SHOPIFY_BACKEND_PID_FILE:-/tmp/shopify_backend.pid}"
LOG_FILE="${SHOPIFY_BACKEND_LOG_FILE:-/tmp/shopify_backend.log}"
ENV_FILE="${SHOPIFY_BACKEND_ENV_FILE:-$ROOT_DIR/.shopify_backend.env}"
PYCACHE_DIR="$SCRIPT_DIR/__pycache__"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  # Always recycle any existing listener so key/config/code changes are applied.
  if lsof -t -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    kill "$(lsof -t -nP -iTCP:"$PORT" -sTCP:LISTEN)" >/dev/null 2>&1 || true
    sleep 0.2
  fi
fi

# Ensure a fresh runtime log and avoid stale cached bytecode from older server versions.
: >"$LOG_FILE"
rm -f "$PYCACHE_DIR"/shopify_backend_server.*.pyc >/dev/null 2>&1 || true

nohup python3 "$SCRIPT_DIR/shopify_backend_server.py" \
  --host "$HOST" \
  --port "$PORT" \
  </dev/null >>"$LOG_FILE" 2>&1 &
BACKEND_PID=$!
disown "$BACKEND_PID" >/dev/null 2>&1 || true
echo "$BACKEND_PID" >"$PID_FILE"

for _ in $(seq 1 60); do
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    break
  fi
  if curl -fsS "http://${HOST}:${PORT}/health" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.25
done

if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
  echo "Backend process exited before becoming healthy. Check $LOG_FILE" >&2
  tail -n 40 "$LOG_FILE" >&2 || true
  exit 1
fi

if ! lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Backend is not listening on ${HOST}:${PORT}. Check $LOG_FILE" >&2
  tail -n 40 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "Backend did not become healthy in time. Check $LOG_FILE" >&2
tail -n 40 "$LOG_FILE" >&2 || true
exit 1
