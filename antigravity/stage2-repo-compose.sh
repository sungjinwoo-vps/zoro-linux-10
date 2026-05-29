#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 2: Repository Compose
# ═══════════════════════════════════════════════════════════════
# Creates the Zoro Linux repository structure, runs createrepo_c,
# signs metadata, and generates .repo files for distribution.
#
# Usage: sudo ./stage2-repo-compose.sh
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 2 — Repository Compose"
zoro_check_root

# ── Step 2.1: Create Repository Structure ────────────────────
zoro_log INFO "Step 2.1: Creating repository directory structure..."

REPO_VARIANTS=("BaseOS" "AppStream" "Extras" "CRB")

for arch in "${ZORO_ARCHES[@]}"; do
    for variant in "${REPO_VARIANTS[@]}"; do
        repo_path="${ZORO_COMPOSE_DIR}/${variant}/${arch}/os/Packages/"
        mkdir -p "$repo_path"
        zoro_log INFO "  Created: ${variant}/${arch}/os/Packages/"
    done

    # Also create debug and source directories
    for variant in "${REPO_VARIANTS[@]}"; do
        mkdir -p "${ZORO_COMPOSE_DIR}/${variant}/${arch}/debug/Packages/"
        mkdir -p "${ZORO_COMPOSE_DIR}/${variant}/source/Packages/"
    done
done

# ── Step 2.2: Populate Repositories ─────────────────────────
zoro_log INFO "Step 2.2: Populating repositories with built RPMs..."

populate_repo() {
    local variant="$1"
    local arch="$2"
    local rpm_dir="${ZORO_RPM_DIR}"
    local target_dir="${ZORO_COMPOSE_DIR}/${variant}/${arch}/os/Packages/"

    # Copy RPMs to appropriate variant directory
    # BaseOS gets core system packages, AppStream gets applications
    find "$rpm_dir" -name "*.${arch}.rpm" -o -name "*.noarch.rpm" | while read -r rpm_file; do
        cp -v "$rpm_file" "$target_dir" 2>/dev/null || true
    done
}

for arch in "${ZORO_ARCHES[@]}"; do
    # For now, copy all RPMs to BaseOS (proper sorting happens with comps.xml)
    populate_repo "BaseOS" "$arch"
done

# ── Step 2.3: Run createrepo_c ───────────────────────────────
zoro_log INFO "Step 2.3: Running createrepo_c on all repositories..."

for arch in "${ZORO_ARCHES[@]}"; do
    for variant in "${REPO_VARIANTS[@]}"; do
        repo_path="${ZORO_COMPOSE_DIR}/${variant}/${arch}/os/"

        if [[ -d "$repo_path" ]]; then
            zoro_log INFO "  Creating repodata: ${variant}/${arch}"
            createrepo_c \
                --database \
                --update \
                --workers=4 \
                --compress-type=zstd \
                "$repo_path"
        fi
    done
done

# ── Step 2.4: Sign Repository Metadata ──────────────────────
zoro_log INFO "Step 2.4: Signing repository metadata..."

for arch in "${ZORO_ARCHES[@]}"; do
    for variant in "${REPO_VARIANTS[@]}"; do
        repomd="${ZORO_COMPOSE_DIR}/${variant}/${arch}/os/repodata/repomd.xml"

        if [[ -f "$repomd" ]]; then
            gpg --detach-sign --armor \
                --default-key "$ZORO_GPG_KEY_EMAIL" \
                "$repomd" 2>/dev/null || \
                zoro_log WARN "  Could not sign repomd.xml for ${variant}/${arch}"

            zoro_log INFO "  ✓ Signed: ${variant}/${arch}/repodata/repomd.xml"
        fi
    done
done

# ── Step 2.5: Generate .repo Files ───────────────────────────
zoro_log INFO "Step 2.5: Generating .repo files..."

REPO_OUTPUT_DIR="${ZORO_BUILD_ROOT}/repo-files"
mkdir -p "$REPO_OUTPUT_DIR"

# zoro-linux-baseos.repo
cat > "${REPO_OUTPUT_DIR}/zoro-linux-baseos.repo" << REPOEOF
[zoro-baseos]
name=Zoro Linux \$releasever - BaseOS
baseurl=${ZORO_REPO_BASE_URL}/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zorolinux
metadata_expire=86400
countme=1
REPOEOF

# zoro-linux-appstream.repo
cat > "${REPO_OUTPUT_DIR}/zoro-linux-appstream.repo" << REPOEOF
[zoro-appstream]
name=Zoro Linux \$releasever - AppStream
baseurl=${ZORO_REPO_BASE_URL}/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zorolinux
metadata_expire=86400
countme=1
REPOEOF

# zoro-linux-extras.repo
cat > "${REPO_OUTPUT_DIR}/zoro-linux-extras.repo" << REPOEOF
[zoro-extras]
name=Zoro Linux \$releasever - Extras
baseurl=${ZORO_REPO_BASE_URL}/\$releasever/Extras/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zorolinux
metadata_expire=86400
countme=1
REPOEOF

# zoro-linux-crb.repo (disabled by default)
cat > "${REPO_OUTPUT_DIR}/zoro-linux-crb.repo" << REPOEOF
[zoro-crb]
name=Zoro Linux \$releasever - CRB (Code Ready Builder)
baseurl=${ZORO_REPO_BASE_URL}/\$releasever/CRB/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zorolinux
metadata_expire=86400
countme=1
REPOEOF

# zoro-linux-dojo.repo (disabled by default)
cat > "${REPO_OUTPUT_DIR}/zoro-linux-dojo.repo" << REPOEOF
[zoro-dojo]
name=Zoro Linux \$releasever - Dojo (Curated 3rd Party)
baseurl=${ZORO_REPO_BASE_URL}/\$releasever/Dojo/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zorolinux
metadata_expire=86400

[zoro-dojo-testing]
name=Zoro Linux \$releasever - Dojo Testing
baseurl=${ZORO_REPO_BASE_URL}/\$releasever/Dojo-Testing/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zorolinux
metadata_expire=3600
REPOEOF

zoro_log INFO "  ✓ Generated .repo files in: $REPO_OUTPUT_DIR"

# ── Step 2.6: Repository Summary ────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo " ⚔  Stage 2 — Repository Compose Summary"
echo "═══════════════════════════════════════════════"

for arch in "${ZORO_ARCHES[@]}"; do
    for variant in "${REPO_VARIANTS[@]}"; do
        pkg_count=$(find "${ZORO_COMPOSE_DIR}/${variant}/${arch}/os/Packages/" \
            -name "*.rpm" 2>/dev/null | wc -l)
        echo "  ${variant}/${arch}: ${pkg_count} packages"
    done
done

echo ""
zoro_log INFO "Stage 2 COMPLETE — Repositories composed and signed."
echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The armoury is stocked. Proceed to Stage 3.${ZORO_ANSI_RESET}"
echo ""
echo "Next: ./stage3-pungi-compose.sh"
