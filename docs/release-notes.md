# ⚔ Zoro Linux 10 — Release Notes (Santoryu Edition)

**Release Date:** TBD
**Version:** 10.0
**Codename:** Santoryu Edition
**Architectures:** x86_64, aarch64

---

## 1. What's New in Zoro Linux 10

Zoro Linux 10 is the inaugural release of the Zoro Linux distribution — a
community-driven, enterprise-grade operating system built on the
three-blade philosophy of **Stability, Speed, and Elegance**.

### Highlights

- **Kernel 6.12.x LTS** — Latest long-term support kernel with full
  hardware support and performance optimisations.
- **DNF5 Package Manager** — Next-generation package manager with faster
  dependency resolution and zstd-compressed RPMs.
- **GNOME 47 (ZoroDeck Shell)** — Custom GNOME shell extension with
  three-blade logo panel, slash-animation app launcher, and katana-edge
  workspace borders.
- **KDE Plasma 6 (ZoroBlade Shell)** — Full Plasma 6 desktop with
  Santoryu theme, ZoroDojo SDDM login screen, and ZoroGreen colour scheme.
- **Five Installation Editions** — Choose the right blade for your needs.
- **Security Hardening** — Out-of-the-box sysctl hardening, kernel module
  blacklist, SELinux enforcing, and firewalld enabled.
- **zoro-fetch** — Custom system info tool written in Go with Zoro-themed
  ASCII art.
- **Original Artwork** — 10 original SVG wallpapers, custom GTK themes
  (ZoroDark + ZoroLight), ZoroIcons, ZoroBlade cursors, Plymouth boot
  animation, and GRUB2 theme.

---

## 2. Installation Editions

| Edition | Codename | Description |
|---------|----------|-------------|
| The Blade | Minimal | Bare OS, CLI only. Smallest footprint. |
| The Strategist | Server | Headless server with sshd, Cockpit, tuned. |
| The Swordsman | Workstation | Full GNOME desktop with dev tools. |
| Santoryu Full | Dojo Edition | Everything: GNOME + KDE + all extras. |
| The Current | Container Host | Podman, crun, CNI, container-optimised. |

Each edition has a dedicated ISO and kickstart configuration.

---

## 3. Package Changes

### New Packages (Zoro Linux Originals)

| Package | Description |
|---------|-------------|
| `zoro-linux-release` | OS identity, repo configs, GPG key |
| `zoro-linux-logos` | Logo assets (SVG, multi-size) |
| `zoro-linux-backgrounds` | 10 original SVG wallpapers |
| `zoro-linux-themes` | ZoroDark + ZoroLight GTK themes |
| `zoro-linux-icon-theme` | ZoroIcons (Papirus fork, recoloured) |
| `zoro-linux-cursor-theme` | ZoroBlade cursor theme |
| `zoro-linux-grub2-theme` | GRUB2 visual theme |
| `zoro-linux-plymouth` | Plymouth boot splash animation |
| `zoro-linux-kde-theme` | KDE Plasma Santoryu theme |
| `zoro-linux-welcome` | First-run welcome application (GTK4) |
| `zoro-linux-cockpit-branding` | Cockpit web console branding |
| `zoro-linux-security-hardening` | sysctl + modprobe hardening |
| `zoro-fetch` | System information tool (Go binary) |

---

## 4. Known Issues

- EPEL 10 may not yet have packages for all architectures. Use
  `dnf install epel-release` to enable.
- KDE Plasma 6 on Wayland may have minor rendering quirks with the
  Santoryu theme on some GPUs.
- The `zoro-welcome` application requires libadwaita; it will not run
  on KDE sessions without GTK4 support.

---

## 5. Security Notices

- SELinux is **enforcing** in all release builds. Do not disable.
- Firewalld is active with sensible defaults per edition:
  - Server/Container: `public` zone
  - Workstation/Dojo: `home` zone
- Kernel hardening applied via `/etc/sysctl.d/99-zoro-hardening.conf`.
- Dangerous kernel modules blacklisted in `/etc/modprobe.d/zoro-blacklist.conf`.

---

## 6. Upgrade Path

Zoro Linux 10 is a first release. In-place upgrades from other EL-based
distributions are not officially supported. Fresh installation is recommended.

---

## 7. Community & Support

| Resource | URL |
|----------|-----|
| Website | https://zorolinux.org |
| Documentation | https://docs.zorolinux.org |
| Forums | https://forums.zorolinux.org |
| Bug Tracker | https://bugs.zorolinux.org |
| Git | https://git.zorolinux.org |
| Matrix | `#zorolinux:matrix.org` |
| IRC | `#zorolinux` on Libera.Chat |
| Mailing List | devel@zorolinux.org |

---

*"Nothing happened." — Roronoa Zoro*
