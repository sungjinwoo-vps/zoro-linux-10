#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 5: ISO Assembly
# ═══════════════════════════════════════════════════════════════
# Assembles the final bootable ISOs: DVD, Minimal, NetInstall.
# Supports both UEFI and BIOS boot.
#
# Usage: sudo ./stage5-iso-assembly.sh [--variant=dvd|minimal|netinstall]
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 5 — ISO Assembly"
zoro_check_root

# Parse arguments
ISO_VARIANT="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        --variant=*) ISO_VARIANT="${1#*=}" ;;
        *) ;;
    esac
    shift
done

# ── ISO Build Functions ──────────────────────────────────────

build_iso() {
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

    # Copy product.img if available
    if [[ -f "${ZORO_BUILD_ROOT}/product.img" ]]; then
        mkdir -p "${iso_tree}/images"
        cp "${ZORO_BUILD_ROOT}/product.img" "${iso_tree}/images/"
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
variant = Santoryu
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

    # ── Build the ISO with xorriso ───────────────────────────
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
            2>&1 | tee "${ZORO_LOG_DIR}/iso-${variant}-${arch}.log" || {
                # Fallback without hybrid boot options
                xorriso -as mkisofs \
                    -V "${ZORO_ISO_LABEL}" \
                    -A "${ZORO_FULL_NAME}" \
                    -o "$iso_path" \
                    -R -J -T \
                    "$iso_tree" \
                    2>&1 | tee "${ZORO_LOG_DIR}/iso-${variant}-${arch}.log"
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
            2>&1 | tee "${ZORO_LOG_DIR}/iso-${variant}-${arch}.log"
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

    # Clean up tree
    rm -rf "$iso_tree"
}

# ── Main: Build All ISOs ─────────────────────────────────────
zoro_log INFO "Building ISOs for variant: $ISO_VARIANT"

for arch in "${ZORO_ARCHES[@]}"; do
    case "$ISO_VARIANT" in
        dvd)       build_iso "dvd" "$arch" ;;
        minimal)   build_iso "minimal" "$arch" ;;
        netinstall) build_iso "netinstall" "$arch" ;;
        all)
            build_iso "dvd" "$arch"
            build_iso "minimal" "$arch"
            build_iso "netinstall" "$arch"
            ;;
    esac
done

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo " ⚔  Stage 5 — ISO Assembly Summary"
echo "═══════════════════════════════════════════════"

find "$ZORO_ISO_DIR" -name "*.iso" 2>/dev/null | while read -r iso; do
    size=$(du -sh "$iso" | awk '{print $1}')
    echo "  $(basename "$iso")  ($size)"
done

echo ""
zoro_log INFO "Stage 5 COMPLETE — ISOs assembled."
echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The swords are drawn. Proceed to Stage 6.${ZORO_ANSI_RESET}"
echo ""
echo "Next: ./stage6-signing.sh"
