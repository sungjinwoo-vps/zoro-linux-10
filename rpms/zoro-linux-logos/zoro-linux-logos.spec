%define debug_package %{nil}

Name:           zoro-linux-logos
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux logos and visual identity assets
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Provides:       system-logos = %{version}-%{release}
Provides:       redhat-logos = %{version}-%{release}
Obsoletes:      centos-stream-logos < %{version}-%{release}
Conflicts:      centos-stream-logos
Conflicts:      fedora-logos

%description
Logo assets for Zoro Linux 10 (Santoryu Edition).
Three-sword SVG logo in multiple sizes for use in bootloader,
installer, desktop, web, and print materials.

All artwork is original — no copyrighted imagery from One Piece.

%install
# Main logos
install -d -m 0755 %{buildroot}%{_datadir}/pixmaps
install -d -m 0755 %{buildroot}%{_datadir}/icons/hicolor/scalable/apps
install -d -m 0755 %{buildroot}%{_datadir}/icons/hicolor/256x256/apps

# Install SVG logo
install -m 0644 %{_sourcedir}/../../artwork/logo/zoro-linux-logo.svg \
    %{buildroot}%{_datadir}/pixmaps/zoro-linux-logo.svg
install -m 0644 %{_sourcedir}/../../artwork/logo/zoro-linux-logo.svg \
    %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/zoro-linux.svg

# Anaconda/system logos directory
install -d -m 0755 %{buildroot}%{_datadir}/pixmaps/bootloader
install -d -m 0755 %{buildroot}%{_datadir}/pixmaps/system-logo-white

%files
%{_datadir}/pixmaps/zoro-linux-logo.svg
%{_datadir}/icons/hicolor/scalable/apps/zoro-linux.svg
%dir %{_datadir}/pixmaps/bootloader
%dir %{_datadir}/pixmaps/system-logo-white

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of Zoro Linux logo assets
