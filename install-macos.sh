#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/Applications/LocalLM"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

UNAME_ARCH="$(uname -m)"
case "$UNAME_ARCH" in
  arm64) PACKAGE_ARCH="arm64" ;;
  x86_64) PACKAGE_ARCH="x64" ;;
  *) PACKAGE_ARCH="$UNAME_ARCH" ;;
esac

ZIP_NAME="LocalLM-macos-$PACKAGE_ARCH.zip"
DOWNLOAD_URL="https://github.com/marioportillohernaiz/LocalLM/releases/latest/download/$ZIP_NAME"
ZIP_PATH="$TMP_DIR/$ZIP_NAME"
EXTRACT_DIR="$TMP_DIR/extract"

echo "Downloading LocalLM for macOS ($PACKAGE_ARCH)..."
curl -fL "$DOWNLOAD_URL" -o "$ZIP_PATH"

echo "Installing LocalLM..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$EXTRACT_DIR"
ditto -x -k "$ZIP_PATH" "$EXTRACT_DIR"

PACKAGE_ROOT="$EXTRACT_DIR/LocalLM-macos-$PACKAGE_ARCH"
if [[ ! -d "$PACKAGE_ROOT" ]]; then
  PACKAGE_ROOT="$EXTRACT_DIR"
fi

cp -R "$PACKAGE_ROOT"/. "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/start-locallm-macos.sh" "$INSTALL_DIR/backend/locallm-backend"

echo "Starting LocalLM..."
"$INSTALL_DIR/start-locallm-macos.sh"

echo "LocalLM installed at $INSTALL_DIR"
