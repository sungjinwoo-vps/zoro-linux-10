#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Zoro Linux — CI Source Preparation
# ═══════════════════════════════════════════════════════════════
# Generates build-time sources that are NOT committed to git:
#   - RPM-GPG-KEY-zorolinux  (public key, for zoro-linux-release)
#   - zoro-linux-logo.png    (rasterized from the SVG)
#
# These are generated rather than committed because:
#   - GPG keys should never live in version control
#   - PNGs are build artifacts derived from the source SVG
#
# Safe to run repeatedly. Used by CI before building RPMs.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

LOGO_SVG="${ROOT_DIR}/artwork/logo/zoro-linux-logo.svg"
RELEASE_SOURCES="${ROOT_DIR}/rpms/zoro-linux-release/SOURCES"

echo "⚔ Preparing CI build sources..."

mkdir -p "${RELEASE_SOURCES}"

# ── 1. Rasterize logo SVG → PNG ──────────────────────────────
LOGO_PNG="${RELEASE_SOURCES}/zoro-linux-logo.png"
if [ -f "${LOGO_SVG}" ]; then
    if command -v rsvg-convert &>/dev/null; then
        rsvg-convert -w 256 -h 256 "${LOGO_SVG}" -o "${LOGO_PNG}"
        echo "  ✓ Logo PNG generated (rsvg-convert)"
    elif command -v inkscape &>/dev/null; then
        inkscape -w 256 -h 256 "${LOGO_SVG}" -o "${LOGO_PNG}" 2>/dev/null
        echo "  ✓ Logo PNG generated (inkscape)"
    elif command -v convert &>/dev/null; then
        convert -background none -resize 256x256 "${LOGO_SVG}" "${LOGO_PNG}"
        echo "  ✓ Logo PNG generated (ImageMagick)"
    else
        # Last resort: 1x1 transparent PNG placeholder so the build proceeds
        printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "${LOGO_PNG}"
        echo "  ⚠ No SVG rasterizer found — wrote placeholder PNG"
    fi
else
    echo "  ✗ Logo SVG not found at ${LOGO_SVG}"
    exit 1
fi

# ── 2. Generate / export GPG public key ──────────────────────
GPG_KEY="${RELEASE_SOURCES}/RPM-GPG-KEY-zorolinux"
if command -v gpg &>/dev/null; then
    GPG_HOME="$(mktemp -d)"
    export GNUPGHOME="${GPG_HOME}"
    chmod 700 "${GPG_HOME}"

    # Ephemeral CI key — real signing key is generated in stage0/stage6
    cat > "${GPG_HOME}/keygen" << 'KEYEOF'
%echo Generating Zoro Linux CI key
Key-Type: RSA
Key-Length: 2048
Name-Real: Zoro Linux Release Key (CI)
Name-Email: security@zorolinux.org
Expire-Date: 0
%no-protection
%commit
%echo done
KEYEOF

    gpg --batch --gen-key "${GPG_HOME}/keygen" 2>/dev/null || true
    gpg --armor --export "security@zorolinux.org" > "${GPG_KEY}" 2>/dev/null || true

    if [ -s "${GPG_KEY}" ]; then
        echo "  ✓ GPG public key exported"
    else
        echo "-----BEGIN PGP PUBLIC KEY BLOCK-----" > "${GPG_KEY}"
        echo "Comment: Zoro Linux CI placeholder key" >> "${GPG_KEY}"
        echo "-----END PGP PUBLIC KEY BLOCK-----" >> "${GPG_KEY}"
        echo "  ⚠ GPG keygen failed — wrote placeholder key"
    fi
    rm -rf "${GPG_HOME}"
else
    echo "-----BEGIN PGP PUBLIC KEY BLOCK-----" > "${GPG_KEY}"
    echo "Comment: Zoro Linux CI placeholder key" >> "${GPG_KEY}"
    echo "-----END PGP PUBLIC KEY BLOCK-----" >> "${GPG_KEY}"
    echo "  ⚠ gpg not available — wrote placeholder key"
fi

echo "  ✓ CI sources prepared."
