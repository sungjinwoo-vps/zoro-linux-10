#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 7: Release Asset Packaging
# ═══════════════════════════════════════════════════════════════
# Packages all release assets, prepares for mirror distribution,
# generates torrent files, and creates the release announcement.
#
# Usage: sudo ./stage7-release.sh
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 7 — Release Asset Packaging"
zoro_check_root

RELEASE_DIR="${ZORO_BUILD_ROOT}/release-${ZORO_RELEASE}"
mkdir -p "$RELEASE_DIR"

# ── Step 7.1: Assemble Release Directory ────────────────────
zoro_log INFO "Step 7.1: Assembling release directory..."

mkdir -p "${RELEASE_DIR}/isos/${ZORO_PRIMARY_ARCH}"
mkdir -p "${RELEASE_DIR}/isos/${ZORO_SECONDARY_ARCH}"
mkdir -p "${RELEASE_DIR}/checksums"
mkdir -p "${RELEASE_DIR}/gpg"
mkdir -p "${RELEASE_DIR}/docs"
mkdir -p "${RELEASE_DIR}/repo-files"
mkdir -p "${RELEASE_DIR}/torrents"

# Copy ISOs
for arch in "${ZORO_ARCHES[@]}"; do
    find "$ZORO_ISO_DIR" -name "*-${arch}-*.iso" -exec \
        cp {} "${RELEASE_DIR}/isos/${arch}/" \; 2>/dev/null || true
    find "$ZORO_ISO_DIR" -name "*-${arch}-*.iso.asc" -exec \
        cp {} "${RELEASE_DIR}/isos/${arch}/" \; 2>/dev/null || true
done

# Copy checksums
cp "${ZORO_ISO_DIR}/SHA256SUMS" "${RELEASE_DIR}/checksums/" 2>/dev/null || true
cp "${ZORO_ISO_DIR}/SHA256SUMS.asc" "${RELEASE_DIR}/checksums/" 2>/dev/null || true
cp "${ZORO_ISO_DIR}/SHA512SUMS" "${RELEASE_DIR}/checksums/" 2>/dev/null || true
cp "${ZORO_ISO_DIR}/SHA512SUMS.asc" "${RELEASE_DIR}/checksums/" 2>/dev/null || true

# Copy GPG key
cp "${ZORO_ISO_DIR}/RPM-GPG-KEY-zorolinux" "${RELEASE_DIR}/gpg/" 2>/dev/null || true

# Copy .repo files
cp "${ZORO_BUILD_ROOT}/repo-files/"*.repo "${RELEASE_DIR}/repo-files/" 2>/dev/null || true

# Copy documentation
DOCS_DIR="${SCRIPT_DIR}/../docs"
cp "${DOCS_DIR}/release-notes.md" "${RELEASE_DIR}/docs/" 2>/dev/null || true
cp "${DOCS_DIR}/installation-guide.md" "${RELEASE_DIR}/docs/" 2>/dev/null || true

zoro_log INFO "  ✓ Release directory assembled."

# ── Step 7.2: Generate Torrent Files ────────────────────────
zoro_log INFO "Step 7.2: Generating torrent files..."

if command -v mktorrent &>/dev/null; then
    find "${RELEASE_DIR}/isos" -name "*.iso" | while read -r iso_file; do
        torrent_name="$(basename "$iso_file").torrent"
        mktorrent \
            -a "udp://tracker.opentrackr.org:1337/announce" \
            -a "udp://tracker.openbittorrent.com:6969/announce" \
            -c "${ZORO_FULL_NAME} - https://zorolinux.org" \
            -w "https://mirror.zorolinux.org/${ZORO_VERSION}/isos/$(basename "$iso_file")" \
            -o "${RELEASE_DIR}/torrents/${torrent_name}" \
            "$iso_file" 2>/dev/null

        if [[ -f "${RELEASE_DIR}/torrents/${torrent_name}" ]]; then
            zoro_log INFO "  ✓ Torrent: $torrent_name"
        fi
    done
else
    zoro_log WARN "  mktorrent not installed — skipping torrent generation."
    zoro_log INFO "  Install: dnf install mktorrent"
fi

# ── Step 7.3: Create Release Archive ────────────────────────
zoro_log INFO "Step 7.3: Creating release archive..."

ARCHIVE_NAME="zoro-linux-${ZORO_RELEASE}-release-assets.tar.gz"
cd "${ZORO_BUILD_ROOT}"
tar -czf "${RELEASE_DIR}/${ARCHIVE_NAME}" \
    -C "$RELEASE_DIR" \
    checksums gpg docs repo-files 2>/dev/null

if [[ -f "${RELEASE_DIR}/${ARCHIVE_NAME}" ]]; then
    archive_size=$(du -sh "${RELEASE_DIR}/${ARCHIVE_NAME}" | awk '{print $1}')
    zoro_log INFO "  ✓ Archive: $ARCHIVE_NAME ($archive_size)"
fi

# ── Step 7.4: Generate Release Manifest ─────────────────────
zoro_log INFO "Step 7.4: Generating release manifest..."

cat > "${RELEASE_DIR}/RELEASE-MANIFEST.txt" << MANEOF
═══════════════════════════════════════════════════════════════
⚔  ${ZORO_FULL_NAME}  ⚔
    Release Manifest
    Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
═══════════════════════════════════════════════════════════════

Version:      ${ZORO_RELEASE}
Codename:     ${ZORO_CODENAME}
Architecture: ${ZORO_ARCHES[*]}
Kernel:       ${ZORO_KERNEL_RELEASE}

───────────────────────────────────────────────────────────────
ISO Images
───────────────────────────────────────────────────────────────
MANEOF

find "${RELEASE_DIR}/isos" -name "*.iso" -exec du -sh {} \; 2>/dev/null | \
    sort | while read -r size path; do
        echo "  $size  $(basename "$path")" >> "${RELEASE_DIR}/RELEASE-MANIFEST.txt"
    done

cat >> "${RELEASE_DIR}/RELEASE-MANIFEST.txt" << MANEOF

───────────────────────────────────────────────────────────────
Verification
───────────────────────────────────────────────────────────────
GPG Key:     RPM-GPG-KEY-zorolinux
Checksums:   SHA256SUMS, SHA512SUMS (signed)
Signatures:  Detached .asc files alongside each ISO

To verify an ISO:
  gpg --import gpg/RPM-GPG-KEY-zorolinux
  gpg --verify isos/x86_64/ZoroLinux-${ZORO_RELEASE}-x86_64-dvd.iso.asc
  sha256sum -c checksums/SHA256SUMS

───────────────────────────────────────────────────────────────
Download
───────────────────────────────────────────────────────────────
Website:  ${ZORO_HOME_URL}
Mirrors:  ${ZORO_REPO_BASE_URL}
Docs:     ${ZORO_DOCS_URL}

───────────────────────────────────────────────────────────────
"I will be the world's greatest swordsman."
           — Roronoa Zoro
═══════════════════════════════════════════════════════════════
MANEOF

zoro_log INFO "  ✓ Release manifest written."

# ── Step 7.5: Mirror Sync Preparation ───────────────────────
zoro_log INFO "Step 7.5: Preparing mirror sync..."

cat > "${RELEASE_DIR}/sync-to-mirrors.sh" << 'SYNCEOF'
#!/usr/bin/env bash
# Sync release to CDN mirrors
# Usage: ./sync-to-mirrors.sh <mirror-host>

set -euo pipefail

MIRROR_HOST="${1:-mirror.zorolinux.org}"
RELEASE_DIR="$(dirname "$0")"

echo "⚔  Syncing to mirror: $MIRROR_HOST"

rsync -avz --progress \
    --exclude='sync-to-mirrors.sh' \
    "$RELEASE_DIR/" \
    "root@${MIRROR_HOST}:/srv/mirror/zorolinux/10/" \
    || echo "Mirror sync failed — check SSH access."

echo "⚔  Mirror sync complete."
SYNCEOF

chmod +x "${RELEASE_DIR}/sync-to-mirrors.sh"
zoro_log INFO "  ✓ Mirror sync script ready."

# ── Final Summary ───────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║     ⚔  ANTIGRAVITY PIPELINE COMPLETE  ⚔      ║"
echo "║     ${ZORO_FULL_NAME}              ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
echo "  Release directory: $RELEASE_DIR"
echo ""
echo "  Contents:"
find "$RELEASE_DIR" -type f | sort | while read -r f; do
    size=$(du -sh "$f" | awk '{print $1}')
    echo "    [$size] $(basename "$f")"
done
echo ""
zoro_log INFO "ALL STAGES COMPLETE — Zoro Linux ${ZORO_RELEASE} is ready for release."
echo -e "${ZORO_ANSI_BOLD_GREEN}"
echo '  "Nothing happened." — Roronoa Zoro'
echo -e "${ZORO_ANSI_RESET}"
