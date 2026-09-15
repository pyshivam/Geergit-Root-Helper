#!/usr/bin/env bash
# Regenerates Android launcher icons from assets/launcher_icon/*.svg.
# Sources of truth: legacy_icon.svg (full-bleed squircle) and
# adaptive_foreground.svg (mark only, 66dp safe zone). Run after edits.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RES_DIR="$PROJECT_ROOT/android/app/src/main/res"
ASSET_DIR="$PROJECT_ROOT/assets/launcher_icon"

declare -A LEGACY=(
  [mipmap-mdpi]=48
  [mipmap-hdpi]=72
  [mipmap-xhdpi]=96
  [mipmap-xxhdpi]=144
  [mipmap-xxxhdpi]=192
)

declare -A ADAPTIVE=(
  [mipmap-mdpi]=108
  [mipmap-hdpi]=162
  [mipmap-xhdpi]=216
  [mipmap-xxhdpi]=324
  [mipmap-xxxhdpi]=432
)

for folder in "${!LEGACY[@]}"; do
  size="${LEGACY[$folder]}"
  inkscape "$ASSET_DIR/legacy_icon.svg" \
    --export-filename="$RES_DIR/$folder/ic_launcher.png" \
    --export-width="$size" \
    --export-height="$size" \
    --export-type=png
  echo "Generated $folder/ic_launcher.png (${size}x${size})"
done

# Adaptive background: white field with the logo at 60% scale (user
# direction 2026-09-15), centered. Full logo as background layer is
# masking-safe and immune to foreground rasterization quirks; the
# foreground is a 1x1 transparent placeholder.
LOGO_SCALE_PCT=60
for folder in "${!ADAPTIVE[@]}"; do
  size="${ADAPTIVE[$folder]}"
  logo_px=$(( size * LOGO_SCALE_PCT / 100 ))
  tmp="$(mktemp --suffix=.png)"
  inkscape "$ASSET_DIR/legacy_icon.svg" \
    --export-filename="$tmp" \
    --export-width="$logo_px" \
    --export-height="$logo_px" \
    --export-type=png
  convert -size "${size}x${size}" xc:'#FFFFFF' \
    "$tmp" -gravity center -composite \
    "$RES_DIR/$folder/ic_launcher_background.png"
  convert -size 1x1 xc:none "$RES_DIR/$folder/ic_launcher_foreground.png"
  rm -f "$tmp"
  echo "Generated $folder/ic_launcher_{background,foreground}.png (${size}x${size}, logo ${logo_px}px)"
done

mkdir -p "$RES_DIR/mipmap-anydpi-v26"
cat > "$RES_DIR/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
EOF
echo "Generated mipmap-anydpi-v26/ic_launcher.xml"
