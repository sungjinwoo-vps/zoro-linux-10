# ═══════════════════════════════════════════════════════════════
# Zoro Linux 10 — Master Build Makefile
# ═══════════════════════════════════════════════════════════════
# Top-level orchestrator for building all Zoro Linux components.
#
# Usage:
#   make help          Show all targets
#   make all           Build everything
#   make rpms          Build all RPM packages
#   make isos          Build all ISOs
#   make check         Verify no upstream branding leaks
# ═══════════════════════════════════════════════════════════════

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Source configuration
-include antigravity/antigravity.conf

# ── Directories ──────────────────────────────────────────────
BUILD_DIR     := $(CURDIR)/build
RPM_SPECS     := $(wildcard rpms/*/zoro-*.spec)
RPM_NAMES     := $(notdir $(patsubst %/,%,$(dir $(RPM_SPECS))))
KICKSTARTS    := $(wildcard installer/kickstarts/*.cfg)

# ═══════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════

.PHONY: help
help:
	@echo ""
	@echo "  ⚔  Zoro Linux 10 — Build System"
	@echo "  ═══════════════════════════════════════"
	@echo ""
	@echo "  Targets:"
	@echo "    make bootstrap    Run Stage 0 (prepare build host)"
	@echo "    make rpms         Build all Zoro Linux RPM packages"
	@echo "    make rpm-release  Build zoro-linux-release RPM"
	@echo "    make rpm-fetch    Build zoro-fetch RPM"
	@echo "    make rpm-themes   Build zoro-linux-themes RPM"
	@echo "    make compose      Run Pungi compose (Stage 3)"
	@echo "    make isos         Build generic ISOs (dvd/minimal/netinstall)"
	@echo "    make isos-editions Build all 5 edition ISOs"
	@echo "    make isos-everything Build everything (generic + editions)"
	@echo "    make iso-blade    Build: The Blade (Minimal) ISO"
	@echo "    make iso-strategist Build: The Strategist (Server) ISO"
	@echo "    make iso-swordsman Build: The Swordsman (Workstation) ISO"
	@echo "    make iso-santoryu Build: Santoryu Full (Dojo) ISO"
	@echo "    make iso-current  Build: The Current (Container Host) ISO"
	@echo "    make sign         Sign ISOs and generate checksums"
	@echo "    make release      Package release assets"
	@echo "    make all          Full pipeline (Stages 0-7)"
	@echo "    make check        Verify no upstream branding leaks"
	@echo "    make lint         Run rpmlint on all specs"
	@echo "    make clean        Clean build artifacts"
	@echo ""
	@echo "  RPM packages found: $(words $(RPM_SPECS))"
	@echo "  Kickstarts found:   $(words $(KICKSTARTS))"
	@echo ""

# ═══════════════════════════════════════════════════════════════
# PIPELINE STAGES
# ═══════════════════════════════════════════════════════════════

.PHONY: bootstrap
bootstrap:
	@echo "⚔  Stage 0: Bootstrap"
	sudo bash antigravity/stage0-bootstrap.sh

.PHONY: srpm-prep
srpm-prep:
	@echo "⚔  Stage 1: SRPM Preparation"
	sudo bash antigravity/stage1-srpm-prep.sh

.PHONY: repo-compose
repo-compose:
	@echo "⚔  Stage 2: Repository Compose"
	sudo bash antigravity/stage2-repo-compose.sh

.PHONY: compose
compose:
	@echo "⚔  Stage 3: Pungi Compose"
	sudo bash antigravity/stage3-pungi-compose.sh

.PHONY: installer
installer:
	@echo "⚔  Stage 4: Lorax / Anaconda"
	sudo bash antigravity/stage4-lorax-anaconda.sh

.PHONY: isos
isos:
	@echo "⚔  Stage 5: ISO Assembly (generic variants)"
	sudo bash antigravity/stage5-iso-assembly.sh --variant=all

.PHONY: isos-editions
isos-editions:
	@echo "⚔  Stage 5: ISO Assembly (all 5 editions)"
	sudo bash antigravity/stage5-iso-assembly.sh --variant=all-editions

.PHONY: isos-everything
isos-everything:
	@echo "⚔  Stage 5: ISO Assembly (everything — generic + editions)"
	sudo bash antigravity/stage5-iso-assembly.sh --variant=everything

.PHONY: iso-blade
iso-blade:
	@echo "⚔  Building: The Blade (Minimal) ISO"
	sudo bash antigravity/stage5-iso-assembly.sh --edition=Blade

.PHONY: iso-strategist
iso-strategist:
	@echo "⚔  Building: The Strategist (Server) ISO"
	sudo bash antigravity/stage5-iso-assembly.sh --edition=Strategist

.PHONY: iso-swordsman
iso-swordsman:
	@echo "⚔  Building: The Swordsman (Workstation) ISO"
	sudo bash antigravity/stage5-iso-assembly.sh --edition=Swordsman

.PHONY: iso-santoryu
iso-santoryu:
	@echo "⚔  Building: Santoryu Full (Dojo Edition) ISO"
	sudo bash antigravity/stage5-iso-assembly.sh --edition=Santoryu

.PHONY: iso-current
iso-current:
	@echo "⚔  Building: The Current (Container Host) ISO"
	sudo bash antigravity/stage5-iso-assembly.sh --edition=Current

.PHONY: sign
sign:
	@echo "⚔  Stage 6: Signing & Checksums"
	sudo bash antigravity/stage6-signing.sh

.PHONY: release
release:
	@echo "⚔  Stage 7: Release Packaging"
	sudo bash antigravity/stage7-release.sh

.PHONY: all
all: bootstrap srpm-prep repo-compose compose installer isos sign release
	@echo ""
	@echo "⚔  ANTIGRAVITY PIPELINE COMPLETE"
	@echo "  \"Nothing happened.\" — Roronoa Zoro"

# ═══════════════════════════════════════════════════════════════
# RPM BUILDS
# ═══════════════════════════════════════════════════════════════

.PHONY: rpms
rpms: rpm-release rpm-fetch rpm-themes rpm-grub rpm-plymouth rpm-welcome \
      rpm-cockpit rpm-security rpm-backgrounds rpm-icons rpm-cursor rpm-kde rpm-logos

.PHONY: rpm-release
rpm-release:
	@echo "⚔  Building: zoro-linux-release"
	rpmbuild -ba rpms/zoro-linux-release/zoro-linux-release.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-release/SOURCES"

.PHONY: rpm-fetch
rpm-fetch:
	@echo "⚔  Building: zoro-fetch"
	cd rpms/zoro-fetch/SOURCES/src && go build -o zoro-fetch .
	rpmbuild -ba rpms/zoro-fetch/zoro-fetch.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-fetch/SOURCES"

.PHONY: rpm-themes
rpm-themes:
	@echo "⚔  Building: zoro-linux-themes"
	rpmbuild -ba rpms/zoro-linux-themes/zoro-linux-themes.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-themes/SOURCES"

.PHONY: rpm-grub
rpm-grub:
	@echo "⚔  Building: zoro-linux-grub2-theme"
	rpmbuild -ba rpms/zoro-linux-grub2-theme/zoro-linux-grub2-theme.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-grub2-theme/SOURCES"

.PHONY: rpm-plymouth
rpm-plymouth:
	@echo "⚔  Building: zoro-linux-plymouth"
	rpmbuild -ba rpms/zoro-linux-plymouth/zoro-linux-plymouth.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-plymouth/SOURCES"

.PHONY: rpm-welcome
rpm-welcome:
	@echo "⚔  Building: zoro-linux-welcome"
	rpmbuild -ba rpms/zoro-linux-welcome/zoro-linux-welcome.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-welcome/SOURCES"

.PHONY: rpm-cockpit
rpm-cockpit:
	@echo "⚔  Building: zoro-linux-cockpit-branding"
	rpmbuild -ba rpms/zoro-linux-cockpit-branding/zoro-linux-cockpit-branding.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-cockpit-branding/SOURCES"

.PHONY: rpm-security
rpm-security:
	@echo "⚔  Building: zoro-linux-security-hardening"
	rpmbuild -ba rpms/zoro-linux-security-hardening/zoro-linux-security-hardening.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-security-hardening/SOURCES"

.PHONY: rpm-backgrounds
rpm-backgrounds:
	@echo "⚔  Building: zoro-linux-backgrounds"
	rpmbuild -ba rpms/zoro-linux-backgrounds/zoro-linux-backgrounds.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-backgrounds/SOURCES"

.PHONY: rpm-icons
rpm-icons:
	@echo "⚔  Building: zoro-linux-icon-theme"
	rpmbuild -ba rpms/zoro-linux-icon-theme/zoro-linux-icon-theme.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-icon-theme/SOURCES"

.PHONY: rpm-cursor
rpm-cursor:
	@echo "⚔  Building: zoro-linux-cursor-theme"
	rpmbuild -ba rpms/zoro-linux-cursor-theme/zoro-linux-cursor-theme.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-cursor-theme/SOURCES"

.PHONY: rpm-kde
rpm-kde:
	@echo "⚔  Building: zoro-linux-kde-theme"
	rpmbuild -ba rpms/zoro-linux-kde-theme/zoro-linux-kde-theme.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-kde-theme/SOURCES"

.PHONY: rpm-logos
rpm-logos:
	@echo "⚔  Building: zoro-linux-logos"
	rpmbuild -ba rpms/zoro-linux-logos/zoro-linux-logos.spec \
		--define "_sourcedir $(CURDIR)/rpms/zoro-linux-logos/SOURCES"

# ═══════════════════════════════════════════════════════════════
# VERIFICATION
# ═══════════════════════════════════════════════════════════════

.PHONY: check
check:
	@echo "⚔  Checking for upstream branding leaks..."
	@echo ""
	@LEAKED=0; \
	for term in "CentOS" "Red Hat" "RHEL" "centos-stream" "Rocky" "AlmaLinux"; do \
		FOUND=$$(grep -rl "$$term" \
			--include="*.spec" --include="*.cfg" --include="*.conf" \
			--include="*.txt" --include="*.css" --include="*.xml" \
			--include="*.py" --include="*.go" --include="*.sh" \
			--include="*.desktop" --include="*.md" --include="*.svg" \
			rpms/ installer/ compose/ shell/ security/ docs/ artwork/ 2>/dev/null \
			| grep -v "antigravity.conf" \
			| grep -v "stage1-srpm-prep.sh" \
			| grep -v "_UPSTREAM_" \
			|| true); \
		if [ -n "$$FOUND" ]; then \
			echo "  ✗ Found '$$term' in:"; \
			echo "$$FOUND" | sed 's/^/      /'; \
			LEAKED=1; \
		fi; \
	done; \
	if [ $$LEAKED -eq 0 ]; then \
		echo "  ✓ No upstream branding leaks detected!"; \
		echo ""; \
		echo "  \"Nothing happened.\" — Roronoa Zoro"; \
	else \
		echo ""; \
		echo "  ⚠ Upstream branding found! Fix before release."; \
	fi

.PHONY: lint
lint:
	@echo "⚔  Running rpmlint on all spec files..."
	@for spec in $(RPM_SPECS); do \
		echo "  Checking: $$spec"; \
		rpmlint "$$spec" 2>&1 || true; \
	done

.PHONY: shellcheck
shellcheck:
	@echo "⚔  Running shellcheck on scripts..."
	@for script in antigravity/*.sh shell/*.sh security/zoro-harden; do \
		echo "  Checking: $$script"; \
		shellcheck "$$script" 2>&1 || true; \
	done

.PHONY: validate-kickstarts
validate-kickstarts:
	@echo "⚔  Validating kickstart files..."
	@for ks in $(KICKSTARTS); do \
		echo "  Checking: $$ks"; \
		ksvalidator "$$ks" 2>&1 || true; \
	done

# ═══════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════

.PHONY: clean
clean:
	@echo "⚔  Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -rf rpms/zoro-fetch/SOURCES/src/zoro-fetch
	@echo "  ✓ Clean."
