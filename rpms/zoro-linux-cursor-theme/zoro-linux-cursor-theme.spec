%define debug_package %{nil}

Name:           zoro-linux-cursor-theme
Version:        10
Release:        1%{?dist}
Summary:        ZoroBlade cursor theme for Zoro Linux
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch

Source0:        cursor.theme
Source1:        build-cursors.sh

%description
ZoroBlade cursor theme for Zoro Linux 10.
Features a katana tip pointer, blade I-beam text cursor,
and spinning blade wait cursor. All in the Zoro green/gold palette.

%install
install -d -m 0755 %{buildroot}%{_datadir}/icons/ZoroBlade
install -m 0644 %{SOURCE0} %{buildroot}%{_datadir}/icons/ZoroBlade/cursor.theme
install -D -m 0755 %{SOURCE1} %{buildroot}%{_libexecdir}/zoro-linux/build-cursors.sh

# Create cursors directory (populated by build script or manually)
install -d -m 0755 %{buildroot}%{_datadir}/icons/ZoroBlade/cursors

%post
# Build cursors if tools are available
if command -v xcursorgen &>/dev/null; then
    %{_libexecdir}/zoro-linux/build-cursors.sh 2>/dev/null || true
fi

%files
%dir %{_datadir}/icons/ZoroBlade
%{_datadir}/icons/ZoroBlade/cursor.theme
%dir %{_datadir}/icons/ZoroBlade/cursors
%{_libexecdir}/zoro-linux/build-cursors.sh

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of ZoroBlade cursor theme
