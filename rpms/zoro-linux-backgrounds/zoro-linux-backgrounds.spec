%define debug_package %{nil}

Name:           zoro-linux-backgrounds
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux desktop wallpapers
License:        CC-BY-SA-4.0
URL:            https://zorolinux.org
BuildArch:      noarch
Provides:       desktop-backgrounds-basic
Provides:       system-backgrounds = %{version}-%{release}

Source0:        wallpapers/
Source1:        zorolinux-backgrounds.xml

%description
Desktop wallpaper collection for Zoro Linux 10 (Santoryu Edition).
Ten original SVG wallpapers in the Zoro Linux colour palette:

  1. The Vow — Default. Three subtle blade silhouettes over dark forest.
  2. Santoryu Flow — Three flowing blade curves (green, silver, gold).
  3. Dojo Floor — Tatami mat grid pattern.
  4. Three Blades — Prominent three-sword X arrangement.
  5. Blade Silver — Minimalist brushed metal.
  6. Forest Deep — Layered green with abstract tree silhouettes.
  7. Katana Edge — Single diagonal slash.
  8. Wado Ichimonji — Elegant flowing white-green curves.
  9. Dawn Training — Warm sunrise over dark forest.
 10. Nothing Happened — Near-black. One green dot.

All artwork is original vector SVG at 3840x2160 resolution.

%install
# Wallpaper images
install -d -m 0755 %{buildroot}%{_datadir}/backgrounds/zorolinux
cp -a %{_sourcedir}/wallpapers/. %{buildroot}%{_datadir}/backgrounds/zorolinux/

# GNOME background properties
install -d -m 0755 %{buildroot}%{_datadir}/gnome-background-properties
install -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/gnome-background-properties/zorolinux-backgrounds.xml

# KDE wallpaper integration (symlink to standard location)
install -d -m 0755 %{buildroot}%{_datadir}/wallpapers/zorolinux
ln -sf %{_datadir}/backgrounds/zorolinux %{buildroot}%{_datadir}/wallpapers/zorolinux/contents

%files
%dir %{_datadir}/backgrounds/zorolinux
%{_datadir}/backgrounds/zorolinux/
%{_datadir}/gnome-background-properties/zorolinux-backgrounds.xml
%dir %{_datadir}/wallpapers/zorolinux
%{_datadir}/wallpapers/zorolinux/contents

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release: 10 original SVG wallpapers
- "The blade reflects nothing but itself."
