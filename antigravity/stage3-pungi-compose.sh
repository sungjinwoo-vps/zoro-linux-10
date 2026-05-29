#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 3: Pungi Compose
# ═══════════════════════════════════════════════════════════════
# Runs the Pungi compose to assemble the OS tree for ISO creation.
#
# Usage: sudo ./stage3-pungi-compose.sh
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 3 — Pungi Compose"
zoro_check_root

COMPOSE_CONF="${SCRIPT_DIR}/../compose/zoro-linux-10.conf"
VARIANTS_XML="${SCRIPT_DIR}/../compose/variants.xml"
COMPS_XML="${SCRIPT_DIR}/../compose/comps-zorolinux-10.xml"

# ── Step 3.1: Validate Compose Configuration ────────────────
zoro_log INFO "Step 3.1: Validating compose configuration..."

for config_file in "$COMPOSE_CONF" "$VARIANTS_XML" "$COMPS_XML"; do
    if [[ ! -f "$config_file" ]]; then
        zoro_log ERROR "Missing config: $config_file"
        exit 1
    fi
done

# Validate XML files
xmllint --noout "$VARIANTS_XML" 2>/dev/null && \
    zoro_log INFO "  ✓ variants.xml is valid" || \
    zoro_log WARN "  ⚠ variants.xml validation failed (xmllint not installed?)"

xmllint --noout "$COMPS_XML" 2>/dev/null && \
    zoro_log INFO "  ✓ comps-zorolinux-10.xml is valid" || \
    zoro_log WARN "  ⚠ comps XML validation failed"

# ── Step 3.2: Prepare Compose Directory ──────────────────────
COMPOSE_OUTPUT="${ZORO_BUILD_ROOT}/compose-${ZORO_RELEASE}-$(date +%Y%m%d)"
mkdir -p "$COMPOSE_OUTPUT"
zoro_log INFO "Step 3.2: Compose output directory: $COMPOSE_OUTPUT"

# ── Step 3.3: Run Pungi Compose ──────────────────────────────
zoro_log INFO "Step 3.3: Running Pungi compose..."

pungi-koji \
    --config="$COMPOSE_CONF" \
    --compose-dir="$COMPOSE_OUTPUT" \
    --label="GA-${ZORO_RELEASE}" \
    --nightly \
    --no-latest-link \
    2>&1 | tee "${ZORO_LOG_DIR}/pungi-compose.log"

PUNGI_EXIT=${PIPESTATUS[0]}

if [[ $PUNGI_EXIT -eq 0 ]]; then
    zoro_log INFO "  ✓ Pungi compose succeeded."
else
    zoro_log ERROR "  ✗ Pungi compose failed. Check: ${ZORO_LOG_DIR}/pungi-compose.log"
    exit 1
fi

# ── Step 3.4: Verify Compose ────────────────────────────────
zoro_log INFO "Step 3.4: Verifying compose output..."

EXPECTED_VARIANTS=("BaseOS" "AppStream")
ALL_VARIANTS_OK=true

for variant in "${EXPECTED_VARIANTS[@]}"; do
    for arch in "${ZORO_ARCHES[@]}"; do
        variant_path="${COMPOSE_OUTPUT}/compose/${variant}/${arch}/os/"
        if [[ -d "$variant_path" ]]; then
            pkg_count=$(find "$variant_path" -name "*.rpm" | wc -l)
            zoro_log INFO "  ✓ ${variant}/${arch}: $pkg_count packages"
        else
            zoro_log WARN "  ✗ Missing: ${variant}/${arch}"
            ALL_VARIANTS_OK=false
        fi
    done
done

# ── Summary ──────────────────────────────────────────────────
echo ""
if $ALL_VARIANTS_OK; then
    zoro_log INFO "Stage 3 COMPLETE — Pungi compose verified."
    echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The formation is set. Proceed to Stage 4.${ZORO_ANSI_RESET}"
else
    zoro_log WARN "Stage 3 PARTIAL — Some variants may be incomplete."
fi

echo ""
echo "Next: ./stage4-lorax-anaconda.sh"
