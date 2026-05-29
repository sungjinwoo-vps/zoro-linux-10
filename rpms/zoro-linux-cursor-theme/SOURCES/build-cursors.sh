#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ZoroBlade Cursor — Build Script
# ═══════════════════════════════════════════════════════════════
# Generates X11/Wayland cursor files from SVG sources.
# Uses xcursorgen to build cursor packages.
#
# Requires: xcursorgen, inkscape (or rsvg-convert)
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/cursors"
SIZES=(24 32 48 64 96)

# Zoro palette
PRIMARY="#2D6A4F"
ACCENT="#52B788"
GOLD="#C9A84C"

echo "⚔  Building ZoroBlade cursor theme"

mkdir -p "$OUTPUT_DIR"

# ── Generate cursor SVGs ────────────────────────────────────

# Default pointer (katana tip)
generate_pointer_svg() {
    local size=$1
    cat > "/tmp/zoroblade-pointer-${size}.svg" << SVGEOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 32 32">
  <!-- Katana tip pointer -->
  <g transform="rotate(-15, 4, 2)">
    <!-- Blade -->
    <polygon points="4,1 8,24 4,22 0,24" fill="${ACCENT}" stroke="${PRIMARY}" stroke-width="0.5"/>
    <!-- Edge highlight -->
    <line x1="4" y1="2" x2="6" y2="20" stroke="white" stroke-width="0.3" opacity="0.5"/>
    <!-- Guard -->
    <ellipse cx="4" cy="24" rx="5" ry="2" fill="${GOLD}" stroke="${PRIMARY}" stroke-width="0.5"/>
    <!-- Handle -->
    <rect x="2.5" y="24" width="3" height="6" rx="1" fill="${PRIMARY}"/>
  </g>
</svg>
SVGEOF
}

# Text cursor (I-beam blade)
generate_text_svg() {
    local size=$1
    cat > "/tmp/zoroblade-text-${size}.svg" << SVGEOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 32 32">
  <line x1="16" y1="4" x2="16" y2="28" stroke="${ACCENT}" stroke-width="2"/>
  <line x1="12" y1="4" x2="20" y2="4" stroke="${ACCENT}" stroke-width="1.5"/>
  <line x1="12" y1="28" x2="20" y2="28" stroke="${ACCENT}" stroke-width="1.5"/>
</svg>
SVGEOF
}

# Wait cursor (spinning blade)
generate_wait_svg() {
    local size=$1
    cat > "/tmp/zoroblade-wait-${size}.svg" << SVGEOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="10" fill="none" stroke="${PRIMARY}" stroke-width="2" opacity="0.3"/>
  <path d="M16,6 A10,10 0 0,1 26,16" fill="none" stroke="${ACCENT}" stroke-width="2.5" stroke-linecap="round"/>
</svg>
SVGEOF
}

# ── Generate PNGs from SVGs ──────────────────────────────────
for size in "${SIZES[@]}"; do
    generate_pointer_svg "$size"
    generate_text_svg "$size"
    generate_wait_svg "$size"

    # Convert SVG to PNG
    for cursor_type in pointer text wait; do
        rsvg-convert -w "$size" -h "$size" \
            "/tmp/zoroblade-${cursor_type}-${size}.svg" \
            -o "/tmp/zoroblade-${cursor_type}-${size}.png" 2>/dev/null || \
        inkscape -w "$size" -h "$size" \
            "/tmp/zoroblade-${cursor_type}-${size}.svg" \
            -o "/tmp/zoroblade-${cursor_type}-${size}.png" 2>/dev/null || true
    done
done

# ── Generate cursor config files ────────────────────────────

# Default arrow
cat > /tmp/zoroblade-default.cursor << CUREOF
24 4 2 /tmp/zoroblade-pointer-24.png 50
32 4 2 /tmp/zoroblade-pointer-32.png 50
48 4 2 /tmp/zoroblade-pointer-48.png 50
CUREOF

# Text cursor
cat > /tmp/zoroblade-text.cursor << CUREOF
24 12 12 /tmp/zoroblade-text-24.png 50
32 16 16 /tmp/zoroblade-text-32.png 50
48 24 24 /tmp/zoroblade-text-48.png 50
CUREOF

# Wait/busy
cat > /tmp/zoroblade-wait.cursor << CUREOF
24 12 12 /tmp/zoroblade-wait-24.png 100
32 16 16 /tmp/zoroblade-wait-32.png 100
48 24 24 /tmp/zoroblade-wait-48.png 100
CUREOF

# ── Build cursor files with xcursorgen ──────────────────────
if command -v xcursorgen &>/dev/null; then
    xcursorgen /tmp/zoroblade-default.cursor "$OUTPUT_DIR/default" 2>/dev/null || true
    xcursorgen /tmp/zoroblade-text.cursor "$OUTPUT_DIR/text" 2>/dev/null || true
    xcursorgen /tmp/zoroblade-wait.cursor "$OUTPUT_DIR/wait" 2>/dev/null || true

    # Create symlinks for standard cursor names
    cd "$OUTPUT_DIR"
    ln -sf default left_ptr
    ln -sf default arrow
    ln -sf default top_left_arrow
    ln -sf text xterm
    ln -sf text ibeam
    ln -sf wait watch
    ln -sf wait progress
    ln -sf wait left_ptr_watch

    echo "  ✓ ZoroBlade cursors built in: $OUTPUT_DIR"
else
    echo "  ⚠ xcursorgen not found — skipping cursor build"
    echo "  Install: dnf install xorg-x11-apps"
fi

# Clean up
rm -f /tmp/zoroblade-*.svg /tmp/zoroblade-*.png /tmp/zoroblade-*.cursor

echo "  ⚔ ZoroBlade cursor theme complete."
