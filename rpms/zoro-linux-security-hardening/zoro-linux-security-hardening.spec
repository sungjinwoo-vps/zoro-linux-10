%define debug_package %{nil}

Name:           zoro-linux-security-hardening
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux security hardening profiles and tools
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       bash
Requires:       coreutils
Requires:       systemd
Recommends:     openscap-scanner
Recommends:     scap-security-guide

Source0:        99-zoro-hardening.conf
Source1:        zoro-blacklist.conf
Source2:        zoro-harden

%description
Security hardening package for Zoro Linux 10 (Santoryu Edition).

Includes:
  - Kernel sysctl hardening parameters
  - Kernel module blacklist for unused protocols
  - zoro-harden CLI tool for applying CIS/STIG profiles
  - Optional OpenSCAP integration

Profiles available:
  - zoro-default: Recommended baseline hardening
  - cis-l1: CIS Benchmark Level 1
  - cis-l2: CIS Benchmark Level 2
  - stig: DISA STIG profile

Usage: sudo zoro-harden --profile=cis-l2

%install
install -D -m 0644 %{SOURCE0} %{buildroot}%{_sysconfdir}/sysctl.d/99-zoro-hardening.conf
install -D -m 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/modprobe.d/zoro-blacklist.conf
install -D -m 0755 %{SOURCE2} %{buildroot}%{_sbindir}/zoro-harden
install -d -m 0755 %{buildroot}/var/lib/zoro-harden/backups

# Man page
install -D -m 0644 %{_sourcedir}/../../../docs/man/zoro-harden.8 \
    %{buildroot}%{_mandir}/man8/zoro-harden.8 2>/dev/null || true

%post
# Apply sysctl settings
sysctl --system 2>/dev/null || true

%files
%config(noreplace) %{_sysconfdir}/sysctl.d/99-zoro-hardening.conf
%config(noreplace) %{_sysconfdir}/modprobe.d/zoro-blacklist.conf
%{_sbindir}/zoro-harden
%dir /var/lib/zoro-harden
%dir /var/lib/zoro-harden/backups
%{_mandir}/man8/zoro-harden.8*

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of security hardening package
- Kernel sysctl hardening (dmesg_restrict, kptr_restrict, ASLR, etc.)
- Module blacklist for 20+ unused protocols
- zoro-harden CLI with CIS L1/L2 and STIG profiles
