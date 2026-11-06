#!/usr/bin/env bash
set -euo pipefail

PRERELEASE="$1"
VERSION="$2"

KEYSTORE_B64="$3"

echo "$KEYSTORE_B64" | base64 --decode > "/tmp/release.keystore"

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="/tmp/release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$4"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$5"

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="./ci_tools/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="android"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"

# Obtener presets como nombre\truta
PRESETS=$(godot --headless --no-header --quit --script "res://ci_tools/get_export_presets.gd" 2>/dev/null)

# Tipo de exportacion: --export-debug si es prerelease (development) y --export-release si es release (master)
if [ "$PRERELEASE" = "true" ]; then
  export_type="debug"
else
  export_type="release"
fi

# Exportar
echo "$PRESETS" | while IFS=$'\t' read -r NAME EXPORT_PATH; do
  if [ -n "$NAME" ]; then
    echo "Exportando preset: $NAME -> $EXPORT_PATH"
    mkdir -p "$(dirname "$EXPORT_PATH")"
    godot --headless --export-$export_type "$NAME" "$EXPORT_PATH"
  fi
done

# Exportar parche
mkdir -p patch
godot --headless --export-pack "Android (universal)" ./patch/patch-"$VERSION".pck
# echo "patch_file=${{ github.workspace }}/patch/patch-${{ steps.version.outputs.new_tag }}.pck" >> "$GITHUB_OUTPUT"