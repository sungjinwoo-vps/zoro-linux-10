%define debug_package %{nil}

Name:           zoro-linux-release
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux 10 release files
License:        GPLv2
URL:            https://zorolinux.org
Group:          System Environment/Base
BuildArch:      noarch

# CRITICAL: This package replaces the upstream brand package
Provides:       system-release = %{version}-%{release}
Provides:       system-release(releasever) = %{version}
Provides:       redhat-release = %{version}-%{release}
Provides:       centos-stream-release = %{version}-%{release}
Obsoletes:      centos-stream-release < %{version}-%{release}
Obsoletes:      centos-stream-release-core < %{version}-%{release}
Obsoletes:      centos-stream-repos < %{version}-%{release}
Conflicts:      centos-stream-release
Conflicts:      centos-stream-release-core
Conflicts:      centos-stream-repos
Conflicts:      fedora-release
Conflicts:      rocky-release
Conflicts:      almalinux-release

# Sources
Source0:        os-release
Source1:        zoro-release
Source2:        issue
Source3:        issue.net
Source4:        motd
Source10:       zoro-linux-baseos.repo
Source11:       zoro-linux-appstream.repo
Source12:       zoro-linux-extras.repo
Source13:       zoro-linux-crb.repo
Source14:       zoro-linux-dojo.repo
Source20:       RPM-GPG-KEY-zorolinux
Source30:       zoro-linux-logo.png
Source31:       zoro-linux-logo.svg

Requires:       coreutils
Requires:       sed
Requires:       grep

%description
Zoro Linux 10 (Santoryu Edition) release files. This package provides
the system identification files and repository configurations for
Zoro Linux, a community-driven enterprise-grade Linux distribution
inspired by Roronoa Zoro's three-sword philosophy.

This package includes:
  - /etc/os-release: OS identification
  - /etc/zoro-release: Version string
  - /etc/issue, /etc/issue.net: Login banners
  - /etc/motd: Message of the Day
  - Repository configuration files
  - GPG signing key for package verification

"Nothing happened." — Roronoa Zoro

%prep
# Nothing to prep — all files are pre-built sources

%build
# Nothing to build

%install
rm -rf %{buildroot}

# ── OS Identification Files ──────────────────────────────────
install -d -m 0755 %{buildroot}%{_prefix}/lib
install -d -m 0755 %{buildroot}%{_sysconfdir}

# Install os-release to /usr/lib/ (canonical location)
install -m 0644 %{SOURCE0} %{buildroot}%{_prefix}/lib/os-release

# Symlink /etc/os-release → /usr/lib/os-release
ln -sf ../usr/lib/os-release %{buildroot}%{_sysconfdir}/os-release

# Install other identification files
install -m 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/zoro-release
install -m 0644 %{SOURCE2} %{buildroot}%{_sysconfdir}/issue
install -m 0644 %{SOURCE3} %{buildroot}%{_sysconfdir}/issue.net
install -m 0644 %{SOURCE4} %{buildroot}%{_sysconfdir}/motd

# Compatibility symlinks
ln -sf zoro-release %{buildroot}%{_sysconfdir}/system-release
ln -sf zoro-release %{buildroot}%{_sysconfdir}/redhat-release
ln -sf zoro-release %{buildroot}%{_sysconfdir}/centos-release

# os.release.d drop-in directory
install -d -m 0755 %{buildroot}%{_prefix}/lib/os.release.d

# ── Repository Files ─────────────────────────────────────────
install -d -m 0755 %{buildroot}%{_sysconfdir}/yum.repos.d

install -m 0644 %{SOURCE10} %{buildroot}%{_sysconfdir}/yum.repos.d/zoro-linux-baseos.repo
install -m 0644 %{SOURCE11} %{buildroot}%{_sysconfdir}/yum.repos.d/zoro-linux-appstream.repo
install -m 0644 %{SOURCE12} %{buildroot}%{_sysconfdir}/yum.repos.d/zoro-linux-extras.repo
install -m 0644 %{SOURCE13} %{buildroot}%{_sysconfdir}/yum.repos.d/zoro-linux-crb.repo
install -m 0644 %{SOURCE14} %{buildroot}%{_sysconfdir}/yum.repos.d/zoro-linux-dojo.repo

# ── GPG Key ──────────────────────────────────────────────────
install -d -m 0755 %{buildroot}%{_sysconfdir}/pki/rpm-gpg
install -m 0644 %{SOURCE20} %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-zorolinux

# ── Logo Assets ──────────────────────────────────────────────
install -d -m 0755 %{buildroot}%{_datadir}/pixmaps
install -m 0644 %{SOURCE30} %{buildroot}%{_datadir}/pixmaps/zoro-linux-logo.png
install -m 0644 %{SOURCE31} %{buildroot}%{_datadir}/pixmaps/zoro-linux-logo.svg

# ── DNF Variables ────────────────────────────────────────────
install -d -m 0755 %{buildroot}%{_sysconfdir}/dnf/vars
echo "%{version}" > %{buildroot}%{_sysconfdir}/dnf/vars/releasever
echo "zorolinux" > %{buildroot}%{_sysconfdir}/dnf/vars/infra

%post
# Import GPG key for RPM package verification
rpm --import %{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-zorolinux 2>/dev/null || true

%files
%defattr(-,root,root,-)
# OS identification
%{_prefix}/lib/os-release
%config(noreplace) %{_sysconfdir}/os-release
%config(noreplace) %{_sysconfdir}/zoro-release
%{_sysconfdir}/system-release
%{_sysconfdir}/redhat-release
%{_sysconfdir}/centos-release
%config(noreplace) %{_sysconfdir}/issue
%config(noreplace) %{_sysconfdir}/issue.net
%config(noreplace) %{_sysconfdir}/motd
%dir %{_prefix}/lib/os.release.d

# Repository files
%config(noreplace) %{_sysconfdir}/yum.repos.d/zoro-linux-baseos.repo
%config(noreplace) %{_sysconfdir}/yum.repos.d/zoro-linux-appstream.repo
%config(noreplace) %{_sysconfdir}/yum.repos.d/zoro-linux-extras.repo
%config(noreplace) %{_sysconfdir}/yum.repos.d/zoro-linux-crb.repo
%config(noreplace) %{_sysconfdir}/yum.repos.d/zoro-linux-dojo.repo

# GPG key
%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-zorolinux

# Logo assets
%{_datadir}/pixmaps/zoro-linux-logo.png
%{_datadir}/pixmaps/zoro-linux-logo.svg

# DNF variables
%dir %{_sysconfdir}/dnf/vars
%{_sysconfdir}/dnf/vars/releasever
%{_sysconfdir}/dnf/vars/infra

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of Zoro Linux 10 (Santoryu Edition)
- Complete branding: os-release, issue, motd
- Repository configurations: baseos, appstream, extras, crb, dojo
- GPG signing key for package verification
- Logo assets for desktop integration
- "I will never lose again." — Roronoa Zoro
