# ⚔ Zoro Linux 10 — Installation Guide

**Version:** 10.0 (Santoryu Edition)
**Architectures:** x86_64, aarch64

---

## 1. System Requirements

### Minimum

| Component | Requirement |
|-----------|-------------|
| CPU | 64-bit x86_64 or aarch64 processor |
| RAM | 2 GB (CLI), 4 GB (Desktop) |
| Disk | 20 GB (Minimal), 40 GB (Desktop), 80 GB (Santoryu Full) |
| Network | Optional (required for NetInstall) |

### Recommended

| Component | Recommendation |
|-----------|---------------|
| CPU | 4+ cores, 2 GHz+ |
| RAM | 8 GB+ |
| Disk | 100 GB+ SSD |
| GPU | Any with open-source driver support |

---

## 2. Download

Download ISOs from: **https://zorolinux.org/download/**

### Available ISOs

| Filename | Edition | Description |
|----------|---------|-------------|
| `ZoroLinux-10.0-x86_64-Blade.iso` | The Blade | Minimal CLI-only install |
| `ZoroLinux-10.0-x86_64-Strategist.iso` | The Strategist | Headless server + Cockpit |
| `ZoroLinux-10.0-x86_64-Swordsman.iso` | The Swordsman | GNOME workstation + dev tools |
| `ZoroLinux-10.0-x86_64-Santoryu.iso` | Santoryu Full | Everything: GNOME + KDE + all |
| `ZoroLinux-10.0-x86_64-Current.iso` | The Current | Container host (Podman) |

ARM64 variants are also available with `aarch64` in the filename.

### Verify Your Download

```bash
# Import the GPG key
gpg --import RPM-GPG-KEY-zorolinux

# Verify the ISO signature
gpg --verify ZoroLinux-10.0-x86_64-Santoryu.iso.asc

# Verify the checksum
sha256sum -c SHA256SUMS
```

---

## 3. Creating Installation Media

### USB Drive (Recommended)

```bash
# Linux — replace /dev/sdX with your USB device
sudo dd if=ZoroLinux-10.0-x86_64-Santoryu.iso of=/dev/sdX bs=4M status=progress
sync
```

On Windows, use [Rufus](https://rufus.ie/) or [balenaEtcher](https://etcher.io/).

### DVD

Burn the ISO to a DVD using your preferred burning tool.

---

## 4. Installation Walkthrough

### 4.1 Boot from Installation Media

1. Insert the USB drive or DVD.
2. Configure your BIOS/UEFI to boot from the installation media.
3. Select **"Install Zoro Linux 10"** from the boot menu.

### 4.2 Language & Keyboard

Select your preferred language and keyboard layout.

### 4.3 Installation Destination

- **Automatic partitioning** (recommended for most users):
  The installer will create an LVM layout with XFS filesystems.
- **Custom partitioning**:
  Recommended layout:
  - `/boot` — 1 GB, XFS
  - `/boot/efi` — 512 MB, EFI System Partition (UEFI systems)
  - `/` — 50+ GB, XFS (LVM)
  - `/home` — remaining space, XFS (LVM)
  - `swap` — 4–8 GB (LVM)

### 4.4 Network Configuration

Configure networking. DHCP is enabled by default.

### 4.5 Software Selection

If using the interactive installer, select your preferred environment:

| Profile | Environment |
|---------|-------------|
| The Blade | Minimal Install |
| The Strategist | Server |
| The Swordsman | Workstation |
| Santoryu Full | Dojo Edition (Everything) |
| The Current | Container Host |

### 4.6 User Creation

- Root password is **locked by default** (security best practice).
- Create an administrative user with `sudo` (wheel group) access.

### 4.7 Begin Installation

Click **Begin Installation** and wait for the process to complete.
The system will reboot when finished.

---

## 5. Post-Installation

### First Login

On desktop editions, the **zoro-welcome** application will launch
automatically, guiding you through:
- What's New in Zoro Linux 10
- Enabling the Extras repository
- Theme selection
- Documentation links

### Enable Additional Repositories

```bash
# Enable Extras repo
sudo dnf config-manager --set-enabled zoro-extras

# Enable Code Ready Builder (development headers)
sudo dnf config-manager --set-enabled zoro-crb

# Enable EPEL 10 (third-party packages)
sudo dnf install epel-release
```

### System Information

Run `zoro-fetch` to display system information with Zoro-themed ASCII art:

```bash
zoro-fetch
```

### Apply Security Hardening

The default hardening profile is applied automatically. For additional
profiles:

```bash
# Apply CIS Level 2 hardening
sudo zoro-harden --profile=cis-l2

# Check current hardening status
sudo zoro-harden --status
```

---

## 6. Edition-Specific Notes

### The Blade (Minimal)

- No GUI installed. Pure CLI environment.
- SSH is enabled by default.
- Add packages as needed: `sudo dnf install <package>`

### The Strategist (Server)

- Cockpit web console enabled at `https://hostname:9090`
- Automatic security updates enabled via `dnf-automatic`
- Tuned profile: `throughput-performance`

### The Swordsman (Workstation)

- GNOME desktop with ZoroDeck shell theme
- ZoroDark GTK theme applied by default
- Flathub repository pre-configured
- Development tools: gcc, make, cmake, python3, nodejs, podman

### Santoryu Full (Dojo Edition)

- Both GNOME and KDE Plasma installed
- All Zoro themes, icons, cursors, and wallpapers
- Complete development toolchain including Go, Rust, and Cargo
- Cockpit web console enabled
- Virtualization tools available

### The Current (Container Host)

- Podman, Buildah, Skopeo pre-installed
- Overlay storage driver configured
- Rootless containers enabled (`user.max_user_namespaces`)
- Cockpit with Podman management extension

---

## 7. Troubleshooting

### Installation hangs at boot

Try the **Basic Graphics** boot option, which disables hardware
acceleration (`nomodeset`).

### SELinux denials

SELinux is **enforcing** by default. Do not disable it. Instead:

```bash
# Check for denials
sudo ausearch -m avc -ts recent

# Generate a policy module for the denial
sudo audit2allow -a -M mymodule
sudo semodule -i mymodule.pp
```

### Firewall blocking services

```bash
# List active zones and rules
sudo firewall-cmd --list-all

# Allow a service
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

---

*"I will be the world's greatest swordsman." — Roronoa Zoro*
