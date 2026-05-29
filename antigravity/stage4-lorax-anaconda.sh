#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 4: Lorax / Anaconda Customisation
# ═══════════════════════════════════════════════════════════════
# Customises the installer boot images and Anaconda UI with
# Zoro Linux branding, colours, and installation profiles.
#
# Usage: sudo ./stage4-lorax-anaconda.sh
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 4 — Lorax / Anaconda Customisation"
zoro_check_root

INSTALLER_DIR="${SCRIPT_DIR}/../installer"
ARTWORK_DIR="${SCRIPT_DIR}/../artwork"

# ── Step 4.1: Create product.img ─────────────────────────────
zoro_log INFO "Step 4.1: Creating product.img for Anaconda branding..."

PRODUCT_IMG_DIR="${ZORO_BUILD_ROOT}/product-img"
mkdir -p "${PRODUCT_IMG_DIR}/usr/share/anaconda/pixmaps"
mkdir -p "${PRODUCT_IMG_DIR}/usr/share/anaconda/boot"
mkdir -p "${PRODUCT_IMG_DIR}/etc"

# Anaconda product configuration
cat > "${PRODUCT_IMG_DIR}/etc/product.d/zorolinux.conf" << 'PRODEOF'
[Main]
Product=Zoro Linux
Version=10
IsFinal=True
BugURL=https://bugs.zorolinux.org
Variant=Santoryu Edition
PRODEOF

# Copy Zoro branding images
if [[ -d "$ARTWORK_DIR/logo" ]]; then
    cp "${ARTWORK_DIR}/logo/zoro-linux-logo.svg" \
        "${PRODUCT_IMG_DIR}/usr/share/anaconda/pixmaps/" 2>/dev/null || true
fi

# Copy Anaconda CSS overrides
if [[ -f "${INSTALLER_DIR}/anaconda-css/zoro-anaconda.css" ]]; then
    mkdir -p "${PRODUCT_IMG_DIR}/usr/share/anaconda/ui/css/"
    cp "${INSTALLER_DIR}/anaconda-css/zoro-anaconda.css" \
        "${PRODUCT_IMG_DIR}/usr/share/anaconda/ui/css/custom.css"
fi

# Build the product.img
cd "$PRODUCT_IMG_DIR"
find . | cpio -o -H newc | gzip -9 > "${ZORO_BUILD_ROOT}/product.img"
zoro_log INFO "  ✓ product.img created: ${ZORO_BUILD_ROOT}/product.img"

# ── Step 4.2: Prepare Lorax Templates ───────────────────────
zoro_log INFO "Step 4.2: Preparing Lorax template overrides..."

LORAX_TEMPLATE_DIR="${ZORO_BUILD_ROOT}/lorax-templates"
mkdir -p "$LORAX_TEMPLATE_DIR"

# Copy custom lorax templates if they exist
if [[ -d "${INSTALLER_DIR}/lorax-templates" ]]; then
    cp -r "${INSTALLER_DIR}/lorax-templates/"* "$LORAX_TEMPLATE_DIR/" 2>/dev/null || true
fi

# Create lorax boot splash replacement script
cat > "${LORAX_TEMPLATE_DIR}/zoro-lorax-post.tmpl" << 'TMPLEOF'
## Zoro Linux Lorax Post-Processing
## Replace upstream boot images with Zoro Linux branding

<%page args="basearch, libdir, product, root"/>

## Remove upstream splash images
remove ${root}/usr/share/anaconda/boot/splash.png
remove ${root}/usr/share/anaconda/pixmaps/splash.png

## Install Zoro Linux splash
installimg --icon ${root}/usr/share/anaconda/pixmaps/zoro-linux-logo.svg \
    ${root}/usr/share/anaconda/pixmaps/splash.png

## Set product name in boot loader
replace @PRODUCT@ "Zoro Linux" ${root}/usr/share/anaconda/boot/grub.cfg
replace @VERSION@ "10" ${root}/usr/share/anaconda/boot/grub.cfg

## Set syslinux branding
replace @PRODUCT@ "Zoro Linux" ${root}/usr/share/anaconda/boot/syslinux.cfg
replace @VERSION@ "10" ${root}/usr/share/anaconda/boot/syslinux.cfg
TMPLEOF

zoro_log INFO "  ✓ Lorax templates prepared."

# ── Step 4.3: Run Lorax to Build boot.iso ────────────────────
zoro_log INFO "Step 4.3: Running Lorax to build boot.iso..."

# Find the latest compose output
LATEST_COMPOSE=$(find "${ZORO_BUILD_ROOT}" -maxdepth 1 -name "compose-*" -type d | sort -r | head -1)
BASEOS_REPO="${LATEST_COMPOSE}/compose/BaseOS/${ZORO_PRIMARY_ARCH}/os/"
APPSTREAM_REPO="${LATEST_COMPOSE}/compose/AppStream/${ZORO_PRIMARY_ARCH}/os/"

# Fallback to repo dirs if compose not available yet
if [[ ! -d "$BASEOS_REPO" ]]; then
    BASEOS_REPO="${ZORO_COMPOSE_DIR}/BaseOS/${ZORO_PRIMARY_ARCH}/os/"
    APPSTREAM_REPO="${ZORO_COMPOSE_DIR}/AppStream/${ZORO_PRIMARY_ARCH}/os/"
fi

LORAX_OUTPUT="${ZORO_BUILD_ROOT}/lorax-output"
mkdir -p "$LORAX_OUTPUT"

lorax \
    --product="Zoro Linux" \
    --version="${ZORO_VERSION}" \
    --release="${ZORO_RELEASE}" \
    --isfinal \
    --volid="${ZORO_ISO_LABEL}" \
    --variant="Santoryu" \
    --bugurl="${ZORO_BUGS_URL}" \
    --source="$BASEOS_REPO" \
    --source="$APPSTREAM_REPO" \
    --add-template="${LORAX_TEMPLATE_DIR}/zoro-lorax-post.tmpl" \
    "$LORAX_OUTPUT" \
    2>&1 | tee "${ZORO_LOG_DIR}/lorax.log"

LORAX_EXIT=${PIPESTATUS[0]}

if [[ $LORAX_EXIT -eq 0 ]]; then
    zoro_log INFO "  ✓ Lorax build succeeded."
    if [[ -f "${LORAX_OUTPUT}/images/boot.iso" ]]; then
        zoro_log INFO "  ✓ boot.iso created: ${LORAX_OUTPUT}/images/boot.iso"
    fi
else
    zoro_log WARN "  Lorax build had issues. Check: ${ZORO_LOG_DIR}/lorax.log"
fi

# ── Step 4.4: Inject product.img into boot.iso ──────────────
zoro_log INFO "Step 4.4: Injecting product.img into boot.iso..."

if [[ -f "${LORAX_OUTPUT}/images/boot.iso" && -f "${ZORO_BUILD_ROOT}/product.img" ]]; then
    # Mount the ISO, add product.img, rebuild
    MOUNT_DIR="${ZORO_BUILD_ROOT}/iso-mount"
    MODIFIED_DIR="${ZORO_BUILD_ROOT}/iso-modified"
    mkdir -p "$MOUNT_DIR" "$MODIFIED_DIR"

    mount -o loop "${LORAX_OUTPUT}/images/boot.iso" "$MOUNT_DIR" 2>/dev/null || {
        zoro_log WARN "Could not mount boot.iso — will inject during Stage 5."
    }

    if mountpoint -q "$MOUNT_DIR"; then
        cp -a "$MOUNT_DIR/"* "$MODIFIED_DIR/"
        umount "$MOUNT_DIR"
        cp "${ZORO_BUILD_ROOT}/product.img" "${MODIFIED_DIR}/images/"
        zoro_log INFO "  ✓ product.img injected into ISO tree."
    fi
fi

# ── Summary ──────────────────────────────────────────────────
echo ""
zoro_log INFO "Stage 4 COMPLETE — Installer customisation done."
echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The blade is sharpened. Proceed to Stage 5.${ZORO_ANSI_RESET}"
echo ""
echo "Next: ./stage5-iso-assembly.sh"
