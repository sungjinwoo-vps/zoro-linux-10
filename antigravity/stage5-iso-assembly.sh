#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 5: ISO Assembly
# ═══════════════════════════════════════════════════════════════
# Assembles the final bootable ISOs.
#
# Supports TWO modes:
#   Generic variants: dvd, minimal, netinstall  (original behaviour)
#   Named editions:   Blade, Strategist, Swordsman, Santoryu, Current
#
# Usage:
#   sudo ./stage5-iso-assembly.sh                          # default: all-editions
#   sudo ./stage5-iso-assembly.sh --variant=dvd            # generic DVD
#   sudo ./stage5-iso-assembly.sh --variant=minimal        # generic Minimal
#   sudo ./stage5-iso-assembly.sh --variant=netinstall     # generic NetInstall
#   sudo ./stage5-iso-assembly.sh --variant=all            # all generic variants
#   sudo ./stage5-iso-assembly.sh --variant=all-editions   # all 5 editions
#   sudo ./stage5-iso-assembly.sh --edition=Blade          # single edition
#   sudo ./stage5-iso-assembly.sh --edition=Santoryu       # single edition
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 5 — ISO Assembly"
zoro_check_root

# Parse arguments
ISO_VARIANT="all-editions"
SINGLE_EDITION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --variant=*) ISO_VARIANT="${1#*=}" ;;
        --edition=*) SINGLE_EDITION="${1#*=}" ;;
        *) ;;
    esac
    shift
done

KICKSTARTS_DIR="${SCRIPT_DIR}/../installer/kickstarts"

# ── Generic ISO Build Function ───────────────────────────────

build_generic_iso() {
    local variant="$1"     # dvd, minimal, netinstall
    local arch="$2"        # x86_64, aarch64
    local iso_name="${ZORO_ISO_PREFIX}-${ZORO_RELEASE}-${arch}-${variant}.iso"
    local iso_path="${ZORO_ISO_DIR}/${iso_name}"
    local iso_tree="${ZORO_BUILD_ROOT}/iso-tree-${variant}-${arch}"

    zoro_log INFO "Building ISO: $iso_name"

    # Prepare ISO tree
    mkdir -p "$iso_tree"

    # Copy compose tree
    COMPOSE_DIR="${ZORO_BUILD_ROOT}/iso-modified"
    [[ -d "$COMPOSE_DIR" ]] || COMPOSE_DIR="${ZORO_BUILD_ROOT}/lorax-output"

    if [[ -d "$COMPOSE_DIR" ]]; then
        cp -a "$COMPOSE_DIR/"* "$iso_tree/" 2>/dev/null || true
    fi

    # Copy packages based on variant
    case "$variant" in
        dvd)
            # Full DVD — include all packages from BaseOS + AppStream
            mkdir -p "${iso_tree}/BaseOS/Packages" "${iso_tree}/AppStream/Packages"
            cp "${ZORO_COMPOSE_DIR}/BaseOS/${arch}/os/Packages/"*.rpm \
                "${iso_tree}/BaseOS/Packages/" 2>/dev/null || true
            cp "${ZORO_COMPOSE_DIR}/AppStream/${arch}/os/Packages/"*.rpm \
                "${iso_tree}/AppStream/Packages/" 2>/dev/null || true

            # Create repodata for on-disc repos
            createrepo_c "${iso_tree}/BaseOS/" 2>/dev/null || true
            createrepo_c "${iso_tree}/AppStream/" 2>/dev/null || true
            ;;
        minimal)
            # Minimal — only core packages
            mkdir -p "${iso_tree}/BaseOS/Packages"
            # Copy only essential packages (kernel, systemd, dnf, etc.)
            for pkg in kernel systemd dnf rpm bash coreutils; do
                find "${ZORO_COMPOSE_DIR}/BaseOS/${arch}/os/Packages/" \
                    -name "${pkg}*.rpm" -exec cp {} "${iso_tree}/BaseOS/Packages/" \; 2>/dev/null || true
            done
            createrepo_c "${iso_tree}/BaseOS/" 2>/dev/null || true
            ;;
        netinstall)
            # Net install — no packages, just boot + installer
            zoro_log INFO "  Net install: boot-only ISO (packages from network repos)"
            ;;
    esac

    # Finalize and create ISO
    _finalize_iso_tree "$iso_tree" "$arch" ""
    _create_iso "$iso_tree" "$iso_path" "$iso_name" "$arch"

    # Clean up tree
    rm -rf "$iso_tree"
}

# ── Edition ISO Build Function ───────────────────────────────

build_edition_iso() {
    local edition_code="$1"   # Blade, Strategist, Swordsman, Santoryu, Current
    local kickstart="$2"      # ks-blade.cfg, etc.
    local display_name="$3"   # The Blade (Minimal), etc.
    local arch="$4"           # x86_64, aarch64

    local iso_name="${ZORO_ISO_PREFIX}-${ZORO_RELEASE}-${arch}-${edition_code}.iso"
    local iso_path="${ZORO_ISO_DIR}/${iso_name}"
    local iso_tree="${ZORO_BUILD_ROOT}/iso-tree-${edition_code}-${arch}"

    zoro_log INFO "Building Edition ISO: $iso_name — ${display_name}"

    mkdir -p "$iso_tree"

    # Copy compose tree (boot images, EFI, isolinux)
    COMPOSE_DIR="${ZORO_BUILD_ROOT}/iso-modified"
    [[ -d "$COMPOSE_DIR" ]] || COMPOSE_DIR="${ZORO_BUILD_ROOT}/lorax-output"

    if [[ -d "$COMPOSE_DIR" ]]; then
        cp -a "$COMPOSE_DIR/"* "$iso_tree/" 2>/dev/null || true
    fi

    # All editions get full BaseOS + AppStream packages (DVD-class)
    mkdir -p "${iso_tree}/BaseOS/Packages" "${iso_tree}/AppStream/Packages"
    cp "${ZORO_COMPOSE_DIR}/BaseOS/${arch}/os/Packages/"*.rpm \
        "${iso_tree}/BaseOS/Packages/" 2>/dev/null || true
    cp "${ZORO_COMPOSE_DIR}/AppStream/${arch}/os/Packages/"*.rpm \
        "${iso_tree}/AppStream/Packages/" 2>/dev/null || true

    # Create repodata for on-disc repos
    createrepo_c "${iso_tree}/BaseOS/" 2>/dev/null || true
    createrepo_c "${iso_tree}/AppStream/" 2>/dev/null || true

    # Embed the kickstart for this edition
    local ks_path="${KICKSTARTS_DIR}/${kickstart}"
    if [[ -f "$ks_path" ]]; then
        cp "$ks_path" "${iso_tree}/ks.cfg"
        zoro_log INFO "  Embedded kickstart: ${kickstart}"
    else
        zoro_log WARN "  Kickstart not found: ${ks_path}"
    fi

    # Finalize and create ISO
    _finalize_iso_tree "$iso_tree" "$arch" "$edition_code"
    _create_iso "$iso_tree" "$iso_path" "$iso_name" "$arch"

    # Clean up tree
    rm -rf "$iso_tree"
}

# ── Shared: Finalize ISO Tree ────────────────────────────────

_finalize_iso_tree() {
    local iso_tree="$1"
    local arch="$2"
    local edition_code="$3"  # empty for generic ISOs

    # Copy product.img if available
    if [[ -f "${ZORO_BUILD_ROOT}/product.img" ]]; then
        mkdir -p "${iso_tree}/images"
        cp "${ZORO_BUILD_ROOT}/product.img" "${iso_tree}/images/"
    fi

    # Determine variant string for metadata
    local variant_str="Santoryu"
    if [[ -n "$edition_code" ]]; then
        variant_str="$edition_code"
    fi

    # Create .discinfo
    cat > "${iso_tree}/.discinfo" << DISCEOF
$(date +%s)
${ZORO_FULL_NAME}
${arch}
BaseOS
DISCEOF

    # Create .treeinfo
    cat > "${iso_tree}/.treeinfo" << TREEEOF
[general]
name = ${ZORO_NAME}
version = ${ZORO_RELEASE}
arch = ${arch}
family = ${ZORO_NAME}
variant = ${variant_str}
timestamp = $(date +%s)

[release]
name = ${ZORO_FULL_NAME}
short = ZoroLinux
version = ${ZORO_RELEASE}

[variant-BaseOS]
id = BaseOS
name = BaseOS
type = variant
uid = BaseOS
repository = BaseOS

[variant-AppStream]
id = AppStream
name = AppStream
type = variant
uid = AppStream
repository = AppStream
TREEEOF
}

# ── Shared: Create ISO ───────────────────────────────────────

_create_iso() {
    local iso_tree="$1"
    local iso_path="$2"
    local iso_name="$3"
    local arch="$4"

    zoro_log INFO "  Building ISO with xorriso..."

    if [[ "$arch" == "x86_64" ]]; then
        # BIOS + UEFI hybrid boot
        xorriso -as mkisofs \
            -V "${ZORO_ISO_LABEL}" \
            -A "${ZORO_FULL_NAME}" \
            -publisher "Zoro Linux Project" \
            -preparer "Antigravity Build System" \
            -o "$iso_path" \
            -b isolinux/isolinux.bin \
            -c isolinux/boot.cat \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
            -eltorito-alt-boot \
            -e images/efiboot.img \
            -no-emul-boot \
            -isohybrid-gpt-basdat \
            -R -J -T \
            "$iso_tree" \
            2>&1 | tee "${ZORO_LOG_DIR}/iso-${iso_name}.log" || {
                # Fallback without hybrid boot options
                xorriso -as mkisofs \
                    -V "${ZORO_ISO_LABEL}" \
                    -A "${ZORO_FULL_NAME}" \
                    -o "$iso_path" \
                    -R -J -T \
                    "$iso_tree" \
                    2>&1 | tee "${ZORO_LOG_DIR}/iso-${iso_name}.log"
            }
    else
        # aarch64 — UEFI boot only
        xorriso -as mkisofs \
            -V "${ZORO_ISO_LABEL}" \
            -A "${ZORO_FULL_NAME}" \
            -o "$iso_path" \
            -e images/efiboot.img \
            -no-emul-boot \
            -R -J -T \
            "$iso_tree" \
            2>&1 | tee "${ZORO_LOG_DIR}/iso-${iso_name}.log"
    fi

    if [[ -f "$iso_path" ]]; then
        local iso_size
        iso_size=$(du -sh "$iso_path" | awk '{print $1}')
        zoro_log INFO "  ✓ ISO built: $iso_name ($iso_size)"

        # Make ISO hybrid bootable (for USB)
        isohybrid "$iso_path" 2>/dev/null || true
    else
        zoro_log ERROR "  ✗ ISO build failed: $iso_name"
        return 1
    fi
}

# ── Helper: Build a Single Edition by Codename ───────────────

build_single_edition() {
    local target_code="$1"
    local arch="$2"
    local found=false

    for edition in "${ZORO_EDITIONS[@]}"; do
        IFS='|' read -r code ks_file display <<< "$edition"
        if [[ "$code" == "$target_code" ]]; then
            build_edition_iso "$code" "$ks_file" "$display" "$arch"
            found=true
            break
        fi
    done

    if ! $found; then
        zoro_log ERROR "Unknown edition: $target_code"
        zoro_log INFO "Available editions:"
        for edition in "${ZORO_EDITIONS[@]}"; do
            IFS='|' read -r code ks_file display <<< "$edition"
            echo "    $code — $display ($ks_file)"
        done
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# Main: Build ISOs
# ═══════════════════════════════════════════════════════════════

zoro_log INFO "Build mode: variant=$ISO_VARIANT edition=$SINGLE_EDITION"

for arch in "${ZORO_ARCHES[@]}"; do
    # If a single edition was requested
    if [[ -n "$SINGLE_EDITION" ]]; then
        build_single_edition "$SINGLE_EDITION" "$arch"
        continue
    fi

    case "$ISO_VARIANT" in
        # ── Generic variants (backwards compatible) ──────────
        dvd)        build_generic_iso "dvd" "$arch" ;;
        minimal)    build_generic_iso "minimal" "$arch" ;;
        netinstall) build_generic_iso "netinstall" "$arch" ;;
        all)
            build_generic_iso "dvd" "$arch"
            build_generic_iso "minimal" "$arch"
            build_generic_iso "netinstall" "$arch"
            ;;

        # ── Named editions (new) ─────────────────────────────
        all-editions)
            for edition in "${ZORO_EDITIONS[@]}"; do
                IFS='|' read -r code ks_file display <<< "$edition"
                build_edition_iso "$code" "$ks_file" "$display" "$arch"
            done
            ;;

        # ── Everything: all generic + all editions ───────────
        everything)
            build_generic_iso "dvd" "$arch"
            build_generic_iso "minimal" "$arch"
            build_generic_iso "netinstall" "$arch"
            for edition in "${ZORO_EDITIONS[@]}"; do
                IFS='|' read -r code ks_file display <<< "$edition"
                build_edition_iso "$code" "$ks_file" "$display" "$arch"
            done
            ;;

        *)
            # Try as an edition codename
            build_single_edition "$ISO_VARIANT" "$arch"
            ;;
    esac
done

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo " ⚔  Stage 5 — ISO Assembly Summary"
echo "═══════════════════════════════════════════════"

ISO_COUNT=0
while read -r iso; do
    size=$(du -sh "$iso" | awk '{print $1}')
    echo "  $(basename "$iso")  ($size)"
    ISO_COUNT=$((ISO_COUNT + 1))
done < <(find "$ZORO_ISO_DIR" -name "*.iso" 2>/dev/null | sort)

echo ""
echo "  Total ISOs built: $ISO_COUNT"
echo ""

if [[ $ISO_COUNT -gt 0 ]]; then
    zoro_log INFO "Stage 5 COMPLETE — $ISO_COUNT ISOs assembled."
    echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The swords are drawn. Proceed to Stage 6.${ZORO_ANSI_RESET}"
else
    zoro_log WARN "Stage 5 — No ISOs were built. Check logs."
fi

echo ""
echo "Next: ./stage6-signing.sh"
