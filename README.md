# ⚔️ Zoro Linux 10 — Santoryu Edition

<p align="center">
  <strong>An enterprise-grade Linux distribution with the spirit of a swordsman.</strong>
</p>

---

## Overview

Zoro Linux is a community-driven enterprise Linux distribution built on an Enterprise Linux 10 foundation. It features custom branding, security hardening, and a fully automated build pipeline.

| | |
|---|---|
| **Base** | Enterprise Linux 10 (Community Build) |
| **Kernel** | 6.12.x |
| **Architectures** | x86_64, aarch64 |
| **Desktop** | GNOME 47 + KDE Plasma 6 |
| **Theme** | Forest Green / Blade Green / Katana Gold |

## Editions

| Edition | Kickstart | Description |
|---------|-----------|-------------|
| **Santoryu** (Full) | `ks-santoryu.cfg` | GNOME + KDE + all tools |
| **Blade** (Minimal) | `ks-blade.cfg` | CLI-only server |
| **Swordsman** (Dev) | `ks-swordsman.cfg` | GNOME + dev tools |
| **Current** (Container) | `ks-current.cfg` | Container-optimized host |
| **Strategist** (Server) | `ks-strategist.cfg` | Headless + Cockpit |

## Build Pipeline

The **Antigravity** build system automates the full ISO creation:

```
make all    # Full pipeline (stages 0-7)
make rpms   # Build custom RPMs only
make isos   # Build ISOs only
make check  # Verify no upstream branding leaks
```

### Stages

| # | Stage | What it does |
|---|-------|--------------|
| 0 | Bootstrap | Prepare build host |
| 1 | SRPM Prep | Fork & rebrand upstream packages |
| 2 | Repo Compose | Create BaseOS/AppStream repos |
| 3 | Pungi Compose | Assemble OS tree |
| 4 | Lorax/Anaconda | Generate installer images |
| 5 | ISO Assembly | Build bootable ISOs |
| 6 | Signing | GPG sign + checksums |
| 7 | Release | Package for distribution |

## CI/CD

Push to `dev` branch triggers the GitHub Actions pipeline automatically:
- Validates specs, scripts, and kickstarts
- Builds all 14 custom RPMs
- Composes repository
- Assembles bootable ISO
- Uploads artifacts

## Project Structure

```
zorolinux-build/
├── antigravity/       # Build pipeline scripts + config
├── rpms/              # 14 custom RPM packages
├── installer/         # Kickstarts + Anaconda customization
├── compose/           # Pungi compose configuration
├── security/          # Hardening tools + sysctl
├── shell/             # Shell prompt themes
├── artwork/           # Logo SVGs
├── docs/              # Man pages
├── Makefile           # Master build orchestrator
└── .github/workflows/ # CI/CD pipeline
```

## License

Original artwork and scripts: MIT  
Rebuilt packages follow their upstream licenses (GPLv2, etc.)

---

<p align="center"><em>Three swords. One OS. No compromises.</em></p>
