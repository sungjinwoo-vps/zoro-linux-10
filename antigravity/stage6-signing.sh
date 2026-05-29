#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 6: Signing & Checksums
# ═══════════════════════════════════════════════════════════════
# GPG signs all ISOs, generates SHA256/SHA512 checksums,
# and publishes the signing key.
#
# Usage: sudo ./stage6-signing.sh
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 6 — Signing & Checksums"
zoro_check_root

# ── Step 6.1: GPG Sign All ISOs ──────────────────────────────
zoro_log INFO "Step 6.1: GPG signing ISOs..."

find "$ZORO_ISO_DIR" -name "*.iso" | while read -r iso_file; do
    iso_name=$(basename "$iso_file")

    # Remove old signatures if present
    rm -f "${iso_file}.asc" "${iso_file}.sig"

    # Create detached ASCII-armored signature
    gpg --detach-sign --armor \
        --default-key "$ZORO_GPG_KEY_EMAIL" \
        --output "${iso_file}.asc" \
        "$iso_file" 2>/dev/null

    if [[ -f "${iso_file}.asc" ]]; then
        zoro_log INFO "  ✓ Signed: ${iso_name}.asc"
    else
        zoro_log ERROR "  ✗ Failed to sign: $iso_name"
    fi
done

# ── Step 6.2: Generate SHA256 Checksums ──────────────────────
zoro_log INFO "Step 6.2: Generating SHA256 checksums..."

cd "$ZORO_ISO_DIR"
sha256sum *.iso > SHA256SUMS 2>/dev/null || {
    zoro_log WARN "No ISOs found for SHA256 checksum generation."
}

if [[ -f SHA256SUMS ]]; then
    zoro_log INFO "  ✓ SHA256SUMS generated:"
    cat SHA256SUMS | while read -r line; do
        echo "    $line"
    done
fi

# ── Step 6.3: Generate SHA512 Checksums ──────────────────────
zoro_log INFO "Step 6.3: Generating SHA512 checksums..."

sha512sum *.iso > SHA512SUMS 2>/dev/null || {
    zoro_log WARN "No ISOs found for SHA512 checksum generation."
}

if [[ -f SHA512SUMS ]]; then
    zoro_log INFO "  ✓ SHA512SUMS generated."
fi

# ── Step 6.4: Sign Checksum Files ───────────────────────────
zoro_log INFO "Step 6.4: Signing checksum files..."

for checksum_file in SHA256SUMS SHA512SUMS; do
    if [[ -f "$checksum_file" ]]; then
        gpg --detach-sign --armor \
            --default-key "$ZORO_GPG_KEY_EMAIL" \
            --output "${checksum_file}.asc" \
            "$checksum_file" 2>/dev/null

        if [[ -f "${checksum_file}.asc" ]]; then
            zoro_log INFO "  ✓ Signed: ${checksum_file}.asc"
        fi
    fi
done

# ── Step 6.5: Export Public Key ──────────────────────────────
zoro_log INFO "Step 6.5: Exporting public GPG key..."

gpg --export --armor "$ZORO_GPG_KEY_EMAIL" > \
    "${ZORO_ISO_DIR}/RPM-GPG-KEY-zorolinux" 2>/dev/null

if [[ -f "${ZORO_ISO_DIR}/RPM-GPG-KEY-zorolinux" ]]; then
    zoro_log INFO "  ✓ Public key exported: RPM-GPG-KEY-zorolinux"
fi

# Also copy to system location
cp "${ZORO_ISO_DIR}/RPM-GPG-KEY-zorolinux" "$ZORO_GPG_KEY_FILE" 2>/dev/null || true

# ── Step 6.6: Verification ──────────────────────────────────
zoro_log INFO "Step 6.6: Verifying signatures..."

VERIFY_OK=true
find "$ZORO_ISO_DIR" -name "*.iso" | while read -r iso_file; do
    if [[ -f "${iso_file}.asc" ]]; then
        if gpg --verify "${iso_file}.asc" "$iso_file" 2>/dev/null; then
            zoro_log INFO "  ✓ Signature verified: $(basename "$iso_file")"
        else
            zoro_log ERROR "  ✗ Signature verification FAILED: $(basename "$iso_file")"
            VERIFY_OK=false
        fi
    fi
done

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo " ⚔  Stage 6 — Signing Summary"
echo "═══════════════════════════════════════════════"
echo "  ISO Directory: $ZORO_ISO_DIR"
echo ""
echo "  Files:"
ls -la "$ZORO_ISO_DIR" 2>/dev/null | grep -v '^total' | while read -r line; do
    echo "    $line"
done

echo ""
zoro_log INFO "Stage 6 COMPLETE — All ISOs signed and checksummed."
echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The seal is set. Proceed to Stage 7.${ZORO_ANSI_RESET}"
echo ""
echo "Next: ./stage7-release.sh"
