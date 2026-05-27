#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_EXE="$ROOT_DIR/backend/locallm-backend"
APP_BUNDLE="$ROOT_DIR/LocalLM.app"
DATA_DIR="$HOME/Library/Application Support/LocalLM/data"
LOG_DIR="$HOME/Library/Logs/LocalLM"
LOG_FILE="$LOG_DIR/backend.log"
OLLAMA_LOG_FILE="$LOG_DIR/ollama.log"
OLLAMA_HOST_URL="${OLLAMA_HOST:-http://127.0.0.1:11434}"

if [[ ! -x "$BACKEND_EXE" ]]; then
  echo "Backend executable not found or not executable: $BACKEND_EXE" >&2
  exit 1
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "LocalLM app bundle not found: $APP_BUNDLE" >&2
  exit 1
fi

mkdir -p "$DATA_DIR" "$LOG_DIR"

ensure_ollama_running() {
  if curl -fsS "$OLLAMA_HOST_URL/api/tags" >/dev/null 2>&1; then
    return
  fi

  if [[ -d "/Applications/Ollama.app" ]]; then
    open -gj -a Ollama >/dev/null 2>&1 || true
  elif command -v ollama >/dev/null 2>&1; then
    OLLAMA_HOST="$OLLAMA_HOST_URL" nohup ollama serve >"$OLLAMA_LOG_FILE" 2>&1 &
  fi

  for _ in $(seq 1 20); do
    if curl -fsS "$OLLAMA_HOST_URL/api/tags" >/dev/null 2>&1; then
      return
    fi
    sleep 1
  done

  echo "Ollama is not reachable at $OLLAMA_HOST_URL. Install or start Ollama before downloading or listing models." >&2
}

ensure_ollama_running

if ! curl -fsS "http://127.0.0.1:8000/health" >/dev/null 2>&1; then
  LOCALLM_DATA_DIR="$DATA_DIR" OLLAMA_HOST="$OLLAMA_HOST_URL" nohup "$BACKEND_EXE" >"$LOG_FILE" 2>&1 &
  sleep 2
fi

open "$APP_BUNDLE"
