#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 1: Source RPM Preparation & Branding
# ═══════════════════════════════════════════════════════════════
# Forks upstream SRPMs, applies Zoro Linux branding patches,
# and rebuilds in a clean mock chroot.
#
# Usage: sudo ./stage1-srpm-prep.sh [--package=NAME]
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 1 — Source RPM Preparation & Branding"
zoro_check_root

# ── Parse Arguments ──────────────────────────────────────────
SINGLE_PACKAGE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --package=*) SINGLE_PACKAGE="${1#*=}" ;;
        *) zoro_log WARN "Unknown argument: $1" ;;
    esac
    shift
done

# ── Packages that need branding patches ──────────────────────
# These are the upstream packages whose SRPMs we fork & rebrand.
BRAND_PACKAGES=(
    "centos-stream-release"
    "centos-logos"
    "centos-backgrounds"
    "centos-indexhtml"
    "cockpit"
    "grub2"
    "anaconda"
    "plymouth"
    "initial-setup"
    "gnome-shell"
    "gnome-settings-daemon"
    "gnome-control-center"
    "firefox"
    "libreoffice"
)

# ── Step 1.1: Download Source RPMs ───────────────────────────
download_srpms() {
    zoro_log INFO "Step 1.1: Downloading source RPMs..."
    mkdir -p "$ZORO_SRPM_DIR"

    for pkg in "${BRAND_PACKAGES[@]}"; do
        if [[ -n "$SINGLE_PACKAGE" && "$pkg" != "$SINGLE_PACKAGE" ]]; then
            continue
        fi

        zoro_log INFO "  Downloading SRPM for: $pkg"

        # Try dnf download first (cleanest method)
        if dnf download --source --destdir="$ZORO_SRPM_DIR" "$pkg" 2>/dev/null; then
            zoro_log INFO "  ✓ Downloaded: $pkg"
        else
            zoro_log WARN "  Could not download SRPM for $pkg via dnf. Trying koji..."
            # Fallback: download from koji
            koji download-build --type=src "$pkg" --destdir="$ZORO_SRPM_DIR" 2>/dev/null || \
                zoro_log ERROR "  ✗ Failed to download SRPM for $pkg"
        fi
    done
}

# ── Step 1.2: Apply Brand Patches ───────────────────────────
apply_brand_patches() {
    local srpm_file="$1"
    local pkg_name="$2"
    local work_dir="${ZORO_BUILD_ROOT}/brand-work/${pkg_name}"

    zoro_log INFO "  Applying brand patches to: $pkg_name"

    # Extract SRPM
    mkdir -p "$work_dir"
    cd "$work_dir"
    rpm2cpio "$srpm_file" | cpio -idmv 2>/dev/null

    # Apply universal string replacements
    # CRITICAL: Replace ALL upstream brand strings with Zoro Linux
    find . -type f \( -name "*.spec" -o -name "*.conf" -o -name "*.txt" \
        -o -name "*.desktop" -o -name "*.xml" -o -name "*.py" \
        -o -name "*.c" -o -name "*.h" -o -name "*.js" -o -name "*.css" \
        -o -name "*.html" -o -name "*.md" -o -name "*.rst" \
        -o -name "*.sh" -o -name "*.in" -o -name "*.json" \) | while read -r file; do

        for upstream_str in "${_UPSTREAM_BRAND_STRINGS[@]}"; do
            case "$upstream_str" in
                "CentOS Stream")
                    sed -i "s/${upstream_str}/${ZORO_NAME}/g" "$file" 2>/dev/null || true
                    ;;
                "CentOS"|"centos")
                    # Be careful not to replace partial matches in URLs etc.
                    sed -i "s/\b${upstream_str}\b/${ZORO_NAME}/g" "$file" 2>/dev/null || true
                    ;;
                "centos-stream")
                    sed -i "s/${upstream_str}/${ZORO_ID}/g" "$file" 2>/dev/null || true
                    ;;
                "Red Hat Enterprise Linux"|"RHEL")
                    sed -i "s/${upstream_str}/${ZORO_NAME}/g" "$file" 2>/dev/null || true
                    ;;
            esac
        done
    done

    # Package-specific patches
    case "$pkg_name" in
        centos-stream-release)
            patch_release_package "$work_dir"
            ;;
        centos-logos)
            patch_logos_package "$work_dir"
            ;;
        grub2)
            patch_grub_package "$work_dir"
            ;;
        anaconda)
            patch_anaconda_package "$work_dir"
            ;;
        plymouth)
            patch_plymouth_package "$work_dir"
            ;;
        cockpit)
            patch_cockpit_package "$work_dir"
            ;;
    esac

    zoro_log INFO "  ✓ Brand patches applied to: $pkg_name"
}

# ── Package-specific patch functions ─────────────────────────

patch_release_package() {
    local work_dir="$1"
    zoro_log INFO "    Patching release package..."

    # This package is entirely replaced by zoro-linux-release.
    # We don't rebuild the upstream one — we build our own.
    zoro_log INFO "    → Release package will be replaced by zoro-linux-release RPM."
    zoro_log INFO "    → See rpms/zoro-linux-release/ for the custom spec."
}

patch_logos_package() {
    local work_dir="$1"
    zoro_log INFO "    Patching logos package..."

    # Replace all logo image files with Zoro Linux logos
    find "$work_dir" -type f \( -name "*.png" -o -name "*.svg" \) | while read -r img; do
        local basename
        basename=$(basename "$img")
        local zoro_logo="${SCRIPT_DIR}/../artwork/logo/zoro-linux-logo.svg"
        if [[ -f "$zoro_logo" ]]; then
            # Convert SVG to appropriate size for each logo slot
            local size
            size=$(identify -format "%wx%h" "$img" 2>/dev/null || echo "256x256")
            rsvg-convert -w "${size%%x*}" -h "${size##*x}" "$zoro_logo" -o "$img" 2>/dev/null || true
        fi
    done
}

patch_grub_package() {
    local work_dir="$1"
    zoro_log INFO "    Patching GRUB2 package..."

    # Patch GRUB distributor string
    find "$work_dir" -name "*.spec" | while read -r spec; do
        sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="Zoro Linux"/g' "$spec"
    done
}

patch_anaconda_package() {
    local work_dir="$1"
    zoro_log INFO "    Patching Anaconda installer..."

    # Patch product name in anaconda
    find "$work_dir" -name "*.py" -o -name "*.glade" | while read -r file; do
        sed -i "s/productName = .*/productName = \"${ZORO_NAME}\"/g" "$file" 2>/dev/null || true
        sed -i "s/productVersion = .*/productVersion = \"${ZORO_VERSION}\"/g" "$file" 2>/dev/null || true
    done
}

patch_plymouth_package() {
    local work_dir="$1"
    zoro_log INFO "    Patching Plymouth..."

    find "$work_dir" -name "*.plymouth" | while read -r file; do
        sed -i "s/Title=.*/Title=Zoro Linux/g" "$file"
    done
}

patch_cockpit_package() {
    local work_dir="$1"
    zoro_log INFO "    Patching Cockpit..."

    find "$work_dir" -name "*.json" -o -name "*.html" | while read -r file; do
        for upstream_str in "${_UPSTREAM_BRAND_STRINGS[@]}"; do
            sed -i "s/${upstream_str}/${ZORO_NAME}/g" "$file" 2>/dev/null || true
        done
    done
}

# ── Step 1.3: Rebuild in Mock ────────────────────────────────
rebuild_in_mock() {
    local srpm_file="$1"
    local pkg_name="$2"

    zoro_log INFO "  Rebuilding in mock: $pkg_name"

    mock -r "$ZORO_MOCK_CONFIG" --rebuild "$srpm_file" \
        --resultdir="${ZORO_RPM_DIR}/${pkg_name}/" \
        --define "dist .el10.zoro" \
        --define "vendor Zoro Linux Project" \
        2>&1 | tee "${ZORO_LOG_DIR}/mock-${pkg_name}.log"

    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        zoro_log INFO "  ✓ Mock build succeeded: $pkg_name"
    else
        zoro_log ERROR "  ✗ Mock build failed: $pkg_name"
        zoro_log ERROR "    See: ${ZORO_LOG_DIR}/mock-${pkg_name}.log"
        return 1
    fi
}

# ── Step 1.4: Lint All RPMs ──────────────────────────────────
lint_rpms() {
    local pkg_name="$1"
    local rpm_dir="${ZORO_RPM_DIR}/${pkg_name}"

    zoro_log INFO "  Running rpmlint on: $pkg_name"

    find "$rpm_dir" -name "*.rpm" | while read -r rpm_file; do
        rpmlint "$rpm_file" 2>&1 | tee -a "${ZORO_LOG_DIR}/rpmlint-${pkg_name}.log"
    done
}

# ── Step 1.5: Sign RPMs ─────────────────────────────────────
sign_rpms() {
    local pkg_name="$1"
    local rpm_dir="${ZORO_RPM_DIR}/${pkg_name}"

    zoro_log INFO "  Signing RPMs for: $pkg_name"

    find "$rpm_dir" -name "*.rpm" | while read -r rpm_file; do
        rpm --addsign "$rpm_file" 2>/dev/null || {
            zoro_log WARN "  Could not sign $rpm_file — is GPG key configured?"
        }
    done
}

# ── Main Execution ───────────────────────────────────────────
main() {
    zoro_ensure_dirs
    mkdir -p "${ZORO_BUILD_ROOT}/brand-work"

    download_srpms

    for srpm_file in "$ZORO_SRPM_DIR"/*.src.rpm; do
        [[ -f "$srpm_file" ]] || continue

        local pkg_name
        pkg_name=$(rpm -qp --queryformat '%{NAME}' "$srpm_file" 2>/dev/null)

        if [[ -n "$SINGLE_PACKAGE" && "$pkg_name" != "$SINGLE_PACKAGE" ]]; then
            continue
        fi

        zoro_log INFO "Processing: $pkg_name"
        apply_brand_patches "$srpm_file" "$pkg_name"

        # Rebuild the modified SRPM
        # First, re-create SRPM from patched sources
        local work_dir="${ZORO_BUILD_ROOT}/brand-work/${pkg_name}"
        local spec_file
        spec_file=$(find "$work_dir" -name "*.spec" -print -quit)

        if [[ -n "$spec_file" ]]; then
            # Build new SRPM from patched spec
            rpmbuild -bs "$spec_file" \
                --define "_topdir ${work_dir}/rpmbuild" \
                --define "_sourcedir ${work_dir}" \
                --define "dist .el10.zoro" \
                2>&1 || {
                    zoro_log ERROR "Failed to create SRPM for $pkg_name"
                    continue
                }

            local new_srpm
            new_srpm=$(find "${work_dir}/rpmbuild/SRPMS/" -name "*.src.rpm" -print -quit)

            if [[ -n "$new_srpm" ]]; then
                rebuild_in_mock "$new_srpm" "$pkg_name"
                lint_rpms "$pkg_name"
                sign_rpms "$pkg_name"
            fi
        fi
    done

    echo ""
    zoro_log INFO "Stage 1 COMPLETE — All packages branded and rebuilt."
    echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The blades are forged. Proceed to Stage 2.${ZORO_ANSI_RESET}"
    echo ""
    echo "Next: ./stage2-repo-compose.sh"
}

main "$@"
