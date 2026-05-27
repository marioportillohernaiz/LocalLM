#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_APP_DIR="$REPO_ROOT/app/flutter_windows_app"
BACKEND_DIR="$REPO_ROOT/backend"
DIST_DIR="$REPO_ROOT/dist"

UNAME_ARCH="$(uname -m)"
case "$UNAME_ARCH" in
  arm64) PACKAGE_ARCH="arm64" ;;
  x86_64) PACKAGE_ARCH="x64" ;;
  *) PACKAGE_ARCH="$UNAME_ARCH" ;;
esac

PACKAGE_ROOT="$DIST_DIR/LocalLM-macos-$PACKAGE_ARCH"
PACKAGE_BACKEND_DIR="$PACKAGE_ROOT/backend"
ZIP_PATH="$DIST_DIR/LocalLM-macos-$PACKAGE_ARCH.zip"
APP_BUNDLE="$FLUTTER_APP_DIR/build/macos/Build/Products/Release/LocalLM.app"
BACKEND_EXE="$BACKEND_DIR/dist/locallm-backend"

echo "Building Flutter macOS app..."
cd "$FLUTTER_APP_DIR"
flutter config --enable-macos-desktop
flutter pub get --enforce-lockfile
flutter build macos --release

echo "Building backend executable..."
cd "$BACKEND_DIR"
if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt pyinstaller
python -m PyInstaller \
  --onefile \
  --name locallm-backend \
  --collect-submodules chromadb \
  run.py

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Flutter release app was not found: $APP_BUNDLE" >&2
  exit 1
fi

if [[ ! -x "$BACKEND_EXE" ]]; then
  echo "Backend executable was not found: $BACKEND_EXE" >&2
  exit 1
fi

echo "Creating package folder..."
rm -rf "$PACKAGE_ROOT" "$ZIP_PATH"
mkdir -p "$PACKAGE_BACKEND_DIR"

cp -R "$APP_BUNDLE" "$PACKAGE_ROOT/"
cp "$BACKEND_EXE" "$PACKAGE_BACKEND_DIR/"
cp "$REPO_ROOT/scripts/start-locallm-macos.sh" "$PACKAGE_ROOT/"
chmod +x "$PACKAGE_ROOT/start-locallm-macos.sh" "$PACKAGE_BACKEND_DIR/locallm-backend"

echo "Creating ZIP..."
cd "$DIST_DIR"
ditto -c -k --sequesterRsrc --keepParent "$(basename "$PACKAGE_ROOT")" "$ZIP_PATH"

echo "Package created: $ZIP_PATH"
echo "Upload this file to a GitHub Release as $(basename "$ZIP_PATH")."
