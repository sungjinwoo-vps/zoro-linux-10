%define debug_package %{nil}

Name:           zoro-linux-icon-theme
Version:        10
Release:        1%{?dist}
Summary:        ZoroIcons — Zoro Linux icon theme
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       papirus-icon-theme
Requires:       hicolor-icon-theme

Source0:        index.theme
Source1:        recolor-papirus.sh

%description
ZoroIcons icon theme for Zoro Linux 10.
A Papirus fork recoloured to the Zoro Linux palette:
  - Folder icons: Forest Green (#2D6A4F) haramaki style
  - Accent icons: Blade Green (#52B788)
  - Status: Gold (#C9A84C) and Silver (#A8B5C8)

%install
install -d -m 0755 %{buildroot}%{_datadir}/icons/ZoroIcons
install -m 0644 %{SOURCE0} %{buildroot}%{_datadir}/icons/ZoroIcons/index.theme
install -D -m 0755 %{SOURCE1} %{buildroot}%{_libexecdir}/zoro-linux/recolor-papirus.sh

%post
# Run recolour on install
if [ -d %{_datadir}/icons/Papirus-Dark ]; then
    %{_libexecdir}/zoro-linux/recolor-papirus.sh %{_datadir}/icons/Papirus-Dark 2>/dev/null || true
fi
# Update icon cache
gtk-update-icon-cache -f %{_datadir}/icons/ZoroIcons 2>/dev/null || true

%files
%dir %{_datadir}/icons/ZoroIcons
%{_datadir}/icons/ZoroIcons/index.theme
%{_libexecdir}/zoro-linux/recolor-papirus.sh

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of ZoroIcons (Papirus fork, Zoro palette)
