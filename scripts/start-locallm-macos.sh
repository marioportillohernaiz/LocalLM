#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_EXE="$ROOT_DIR/backend/locallm-backend"
APP_BUNDLE="$ROOT_DIR/LocalLM.app"
DATA_DIR="$HOME/Library/Application Support/LocalLM/data"
LOG_DIR="$HOME/Library/Logs/LocalLM"
LOG_FILE="$LOG_DIR/backend.log"

if [[ ! -x "$BACKEND_EXE" ]]; then
  echo "Backend executable not found or not executable: $BACKEND_EXE" >&2
  exit 1
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "LocalLM app bundle not found: $APP_BUNDLE" >&2
  exit 1
fi

mkdir -p "$DATA_DIR" "$LOG_DIR"

if ! curl -fsS "http://127.0.0.1:8000/health" >/dev/null 2>&1; then
  LOCALLM_DATA_DIR="$DATA_DIR" nohup "$BACKEND_EXE" >"$LOG_FILE" 2>&1 &
  sleep 2
fi

open "$APP_BUNDLE"
