#!/usr/bin/env bash
set -euo pipefail

PRERELEASE="$1"
VERSION="$2"

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
    godot --headless --export-$export_type "$NAME" "$EXPORT_PATH"
  fi
done

# Exportar parche
mkdir -p patch
godot --headless --export-pack "Android (universal)" ./patch/patch-"$VERSION".pck
# echo "patch_file=${{ github.workspace }}/patch/patch-${{ steps.version.outputs.new_tag }}.pck" >> "$GITHUB_OUTPUT"