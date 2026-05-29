#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# ANTIGRAVITY — Stage 0: Environment Bootstrap
# ═══════════════════════════════════════════════════════════════
# Prepares a fresh EL10 host as a Zoro Linux build machine.
# Run once on a clean CentOS Stream 10 / Rocky 10 / Alma 10 box.
#
# Usage: sudo ./stage0-bootstrap.sh
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/antigravity.conf"

zoro_banner
zoro_log INFO "Stage 0 — Environment Bootstrap"
zoro_check_root
zoro_check_arch

# ── Step 0.1: System Update ──────────────────────────────────
zoro_log INFO "Step 0.1: Updating system packages..."
dnf -y update
dnf -y install dnf-plugins-core

# ── Step 0.2: Enable Required Repos ──────────────────────────
zoro_log INFO "Step 0.2: Enabling CRB (Code Ready Builder) repository..."
dnf config-manager --set-enabled crb 2>/dev/null || \
dnf config-manager --set-enabled powertools 2>/dev/null || \
dnf config-manager --set-enabled codeready-builder 2>/dev/null || \
zoro_log WARN "Could not auto-enable CRB repo — enable manually if needed."

# ── Step 0.3: Install Build Tools ────────────────────────────
zoro_log INFO "Step 0.3: Installing core build tools..."
dnf -y install \
    rpm-build \
    rpm-sign \
    rpmlint \
    rpmdevtools \
    mock \
    createrepo_c \
    xorriso \
    genisoimage \
    syslinux \
    grub2-tools \
    grub2-tools-extra \
    shim-x64 \
    gcc \
    gcc-c++ \
    make \
    cmake \
    git \
    wget \
    curl \
    gnupg2 \
    pinentry-tty

# ── Step 0.4: Install Compose & ISO Tools ────────────────────
zoro_log INFO "Step 0.4: Installing pungi, lorax, and anaconda tools..."
dnf -y install \
    pungi \
    lorax \
    lorax-lmc-novirt \
    anaconda \
    anaconda-tui \
    anaconda-gui \
    pykickstart \
    python3-productmd

# ── Step 0.5: Install Koji (optional — for full build system)
zoro_log INFO "Step 0.5: Installing Koji client..."
dnf -y install \
    koji \
    koji-utils \
    || zoro_log WARN "Koji packages not available — will use mock for builds."

# ── Step 0.6: Install Go (for zoro-fetch) ────────────────────
zoro_log INFO "Step 0.6: Installing Go compiler..."
GO_VERSION="1.22.5"
if ! command -v go &>/dev/null; then
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ZORO_BUILD_ARCH}.tar.gz" \
        -O "/tmp/go${GO_VERSION}.tar.gz"
    tar -C /usr/local -xzf "/tmp/go${GO_VERSION}.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    export PATH=$PATH:/usr/local/go/bin
    rm -f "/tmp/go${GO_VERSION}.tar.gz"
    zoro_log INFO "Go ${GO_VERSION} installed."
else
    zoro_log INFO "Go already installed: $(go version)"
fi

# ── Step 0.7: Install Desktop/Theme Build Dependencies ──────
zoro_log INFO "Step 0.7: Installing theme and artwork build tools..."
dnf -y install \
    gtk3-devel \
    gtk4-devel \
    sassc \
    inkscape \
    ImageMagick \
    optipng \
    librsvg2-tools \
    fontforge \
    grub2-mkfont \
    plymouth-devel \
    || zoro_log WARN "Some optional desktop-build packages unavailable."

# ── Step 0.8: Set Up rpmbuild Directory Structure ────────────
zoro_log INFO "Step 0.8: Setting up rpmbuild directories..."
BUILDER_USER="${SUDO_USER:-builder}"

if ! id "$BUILDER_USER" &>/dev/null; then
    useradd -m -G mock "$BUILDER_USER"
    zoro_log INFO "Created builder user: $BUILDER_USER"
fi

su - "$BUILDER_USER" -c "rpmdev-setuptree" 2>/dev/null || {
    for d in BUILD RPMS SOURCES SPECS SRPMS; do
        mkdir -p "/home/${BUILDER_USER}/rpmbuild/${d}"
    done
}
zoro_log INFO "rpmbuild tree ready at /home/${BUILDER_USER}/rpmbuild/"

# ── Step 0.9: Create Build Directories ───────────────────────
zoro_log INFO "Step 0.9: Creating Zoro build directories..."
zoro_ensure_dirs
chown -R "$BUILDER_USER:$BUILDER_USER" "$ZORO_BUILD_ROOT"

# ── Step 0.10: Generate GPG Key ──────────────────────────────
zoro_log INFO "Step 0.10: GPG key setup..."
if ! gpg --list-keys "$ZORO_GPG_KEY_EMAIL" &>/dev/null; then
    zoro_log INFO "Generating 4096-bit RSA GPG key for package signing..."

    cat > /tmp/zoro-gpg-keygen.conf << GPGEOF
%echo Generating Zoro Linux GPG signing key
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: sign
Name-Real: ${ZORO_GPG_KEY_NAME}
Name-Email: ${ZORO_GPG_KEY_EMAIL}
Expire-Date: ${ZORO_GPG_KEY_EXPIRE}
%no-protection
%commit
%echo Key generation complete
GPGEOF

    gpg --batch --gen-key /tmp/zoro-gpg-keygen.conf
    rm -f /tmp/zoro-gpg-keygen.conf

    # Export public key for RPM verification
    GPG_KEY_ID=$(gpg --list-keys --keyid-format long "$ZORO_GPG_KEY_EMAIL" | \
        grep '^pub' | awk '{print $2}' | cut -d'/' -f2)

    gpg --export --armor "$ZORO_GPG_KEY_EMAIL" > "$ZORO_GPG_KEY_FILE"
    rpm --import "$ZORO_GPG_KEY_FILE"

    zoro_log INFO "GPG key generated. Key ID: $GPG_KEY_ID"
    zoro_log INFO "Public key exported to: $ZORO_GPG_KEY_FILE"

    # Update config with key ID
    sed -i "s/^export ZORO_GPG_KEY_ID=\"\"/export ZORO_GPG_KEY_ID=\"${GPG_KEY_ID}\"/" \
        "${SCRIPT_DIR}/antigravity.conf"
else
    zoro_log INFO "GPG key for ${ZORO_GPG_KEY_EMAIL} already exists."
fi

# ── Step 0.11: Configure Mock ────────────────────────────────
zoro_log INFO "Step 0.11: Configuring mock for Zoro Linux builds..."

cat > "/etc/mock/${ZORO_MOCK_CONFIG}.cfg" << 'MOCKEOF'
# Zoro Linux 10 mock configuration
config_opts['root'] = 'zoro-linux-10-x86_64'
config_opts['target_arch'] = 'x86_64'
config_opts['legal_host_arches'] = ('x86_64',)
config_opts['chroot_setup_cmd'] = 'install @buildsys-build'
config_opts['dist'] = 'el10'
config_opts['releasever'] = '10'
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
config_opts['package_manager'] = 'dnf'

config_opts['dnf.conf'] = """
[main]
keepcache=1
debuglevel=2
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=
install_weak_deps=0
metadata_expire=0
best=1
module_platform_id=platform:el10

[baseos]
name=Zoro Linux 10 - BaseOS
baseurl=https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/os/
gpgcheck=0
enabled=1

[appstream]
name=Zoro Linux 10 - AppStream
baseurl=https://mirror.stream.centos.org/10-stream/AppStream/x86_64/os/
gpgcheck=0
enabled=1

[crb]
name=Zoro Linux 10 - CRB
baseurl=https://mirror.stream.centos.org/10-stream/CRB/x86_64/os/
gpgcheck=0
enabled=1
"""
MOCKEOF

zoro_log INFO "Mock configuration written to /etc/mock/${ZORO_MOCK_CONFIG}.cfg"

# ── Step 0.12: Configure RPM Signing Macros ──────────────────
zoro_log INFO "Step 0.12: Configuring RPM signing macros..."

cat > "/home/${BUILDER_USER}/.rpmmacros" << MACROEOF
%_signature gpg
%_gpg_path /home/${BUILDER_USER}/.gnupg
%_gpg_name ${ZORO_GPG_KEY_EMAIL}
%_gpgbin /usr/bin/gpg2
%dist .el10.zoro
%vendor Zoro Linux Project
%packager Zoro Linux Build System <build@zorolinux.org>
MACROEOF

chown "$BUILDER_USER:$BUILDER_USER" "/home/${BUILDER_USER}/.rpmmacros"
zoro_log INFO "RPM macros configured."

# ── Step 0.13: Verification ──────────────────────────────────
zoro_log INFO "Step 0.13: Verifying bootstrap..."
echo ""
echo "═══════════════════════════════════════════════"
echo " ⚔  Stage 0 Bootstrap — Verification Summary"
echo "═══════════════════════════════════════════════"

TOOLS=("rpmbuild" "mock" "createrepo_c" "pungi-koji" "lorax" "xorriso" "gpg" "rpmlint")
ALL_OK=true

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${ZORO_ANSI_GREEN}✓${ZORO_ANSI_RESET} $tool"
    else
        echo -e "  ${ZORO_ANSI_RED}✗${ZORO_ANSI_RESET} $tool — NOT FOUND"
        ALL_OK=false
    fi
done

if command -v go &>/dev/null; then
    echo -e "  ${ZORO_ANSI_GREEN}✓${ZORO_ANSI_RESET} go — $(go version | awk '{print $3}')"
else
    echo -e "  ${ZORO_ANSI_RED}✗${ZORO_ANSI_RESET} go — NOT FOUND"
    ALL_OK=false
fi

echo ""
if $ALL_OK; then
    zoro_log INFO "Stage 0 COMPLETE — All tools installed and ready."
    echo -e "${ZORO_ANSI_BOLD_GREEN}⚔  The dojo is prepared. Proceed to Stage 1.${ZORO_ANSI_RESET}"
else
    zoro_log WARN "Stage 0 INCOMPLETE — Some tools are missing. Review above."
    echo -e "${ZORO_ANSI_GOLD}⚠  Some tools missing. Install them before proceeding.${ZORO_ANSI_RESET}"
fi

echo ""
echo "Next: ./stage1-srpm-prep.sh"
