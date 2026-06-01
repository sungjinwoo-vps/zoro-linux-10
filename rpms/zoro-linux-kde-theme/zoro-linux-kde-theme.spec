%define debug_package %{nil}

Name:           zoro-linux-kde-theme
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux KDE Plasma theme (ZoroBlade Shell)
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       plasma-workspace
Recommends:     sddm

Source0:        ZoroGreen.colors
# Source1:        Santoryu
# Source2:        ZoroDojo

%description
KDE Plasma theming package for Zoro Linux 10 (ZoroBlade Shell).

Includes:
  - ZoroGreen: Complete KDE color scheme
  - Santoryu: Plasma desktop theme (panel, widgets, tooltips)
  - ZoroDojo: SDDM login greeter theme

All elements use the Zoro Linux palette:
  Forest Green #2D6A4F, Blade Green #52B788,
  Katana Gold #C9A84C, Blade Silver #A8B5C8.

%install
# KDE colour scheme
install -D -m 0644 %{SOURCE0} \
    %{buildroot}%{_datadir}/color-schemes/ZoroGreen.colors

# Plasma theme
install -d -m 0755 %{buildroot}%{_datadir}/plasma/desktoptheme/Santoryu
cp -a %{_sourcedir}/Santoryu/* %{buildroot}%{_datadir}/plasma/desktoptheme/Santoryu/

# SDDM theme
install -d -m 0755 %{buildroot}%{_datadir}/sddm/themes/ZoroDojo
cp -a %{_sourcedir}/ZoroDojo/* %{buildroot}%{_datadir}/sddm/themes/ZoroDojo/

%files
%{_datadir}/color-schemes/ZoroGreen.colors
%dir %{_datadir}/plasma/desktoptheme/Santoryu
%{_datadir}/plasma/desktoptheme/Santoryu/*
%dir %{_datadir}/sddm/themes/ZoroDojo
%{_datadir}/sddm/themes/ZoroDojo/*

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of KDE theme package
- ZoroGreen colour scheme
- Santoryu Plasma theme
- ZoroDojo SDDM login theme
