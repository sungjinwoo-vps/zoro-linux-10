#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ZoroIcons — Papirus Recolour Script
# ═══════════════════════════════════════════════════════════════
# Takes a Papirus icon theme installation and recolours the
# folder icons and key UI elements to the Zoro Linux palette.
#
# Usage: ./recolor-papirus.sh /usr/share/icons/Papirus-Dark
# Output: Recoloured icons in /usr/share/icons/ZoroIcons
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

PAPIRUS_DIR="${1:-/usr/share/icons/Papirus-Dark}"
ZORO_DIR="/usr/share/icons/ZoroIcons"

# Zoro palette
PRIMARY="#2D6A4F"     # Forest Green — replaces folder blue
ACCENT="#52B788"      # Blade Green — replaces teal/cyan accents
GOLD="#C9A84C"        # Katana Gold — replaces orange/yellow
DARK="#1A3A2A"        # Deep Forest — replaces dark blue
SILVER="#A8B5C8"      # Blade Silver — replaces grey

# Papirus default colours to replace
PAPIRUS_BLUE="#5294e2"
PAPIRUS_DARK_BLUE="#3d3846"
PAPIRUS_TEAL="#00bcd4"
PAPIRUS_FOLDER="#5294e2"
PAPIRUS_FOLDER_DARK="#4877b1"

echo "⚔  Recolouring Papirus → ZoroIcons"
echo "  Source: $PAPIRUS_DIR"
echo "  Target: $ZORO_DIR"

# Copy the theme
if [[ -d "$PAPIRUS_DIR" ]]; then
    cp -a "$PAPIRUS_DIR" "$ZORO_DIR"
else
    echo "  ✗ Source Papirus directory not found: $PAPIRUS_DIR"
    exit 1
fi

# Copy our custom index.theme
if [[ -f "$(dirname "$0")/index.theme" ]]; then
    cp "$(dirname "$0")/index.theme" "$ZORO_DIR/index.theme"
fi

# Recolour SVG files
echo "  Recolouring SVG icons..."
find "$ZORO_DIR" -name "*.svg" -type f | while read -r svg_file; do
    # Replace folder blue with Forest Green
    sed -i "s/${PAPIRUS_BLUE}/${PRIMARY}/gI" "$svg_file"
    sed -i "s/${PAPIRUS_FOLDER}/${PRIMARY}/gI" "$svg_file"
    sed -i "s/${PAPIRUS_FOLDER_DARK}/${DARK}/gI" "$svg_file"

    # Replace teal accents with Blade Green
    sed -i "s/${PAPIRUS_TEAL}/${ACCENT}/gI" "$svg_file"

    # Preserve readability — don't touch text/neutral colours
done

# Update icon cache
echo "  Updating icon cache..."
gtk-update-icon-cache -f "$ZORO_DIR" 2>/dev/null || true

echo "  ✓ ZoroIcons ready at: $ZORO_DIR"
echo "  \"The blade cuts only what it must.\""
