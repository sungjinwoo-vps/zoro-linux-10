%define debug_package %{nil}

Name:           zoro-linux-themes
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux GTK and GNOME Shell themes
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       gtk3
Requires:       gnome-shell

Source0:        ZoroDark
Source1:        ZoroLight
Source2:        ZoroDeck

%description
GTK3, GTK4, and GNOME Shell themes for Zoro Linux 10.

Includes two GTK themes:
  - ZoroDark: Dark mode with Forest Green (#2D6A4F) primary,
    Blade Green (#52B788) accents, and Midnight Black base.
  - ZoroLight: Light mode with Dojo Wood (#F0EAD6) surfaces
    and Forest Green highlights.

Includes the ZoroDeck GNOME Shell theme with custom panel,
notification, dash, and overview styling.

%install
# GTK3 themes
install -d -m 0755 %{buildroot}%{_datadir}/themes/ZoroDark/gtk-3.0
install -d -m 0755 %{buildroot}%{_datadir}/themes/ZoroDark/gtk-4.0
install -d -m 0755 %{buildroot}%{_datadir}/themes/ZoroLight/gtk-3.0
install -d -m 0755 %{buildroot}%{_datadir}/themes/ZoroLight/gtk-4.0

install -m 0644 %{SOURCE0}/gtk-3.0/gtk.css %{buildroot}%{_datadir}/themes/ZoroDark/gtk-3.0/
install -m 0644 %{SOURCE0}/gtk-4.0/gtk.css %{buildroot}%{_datadir}/themes/ZoroDark/gtk-4.0/

install -m 0644 %{SOURCE1}/gtk-3.0/gtk.css %{buildroot}%{_datadir}/themes/ZoroLight/gtk-3.0/
install -m 0644 %{SOURCE1}/gtk-4.0/gtk.css %{buildroot}%{_datadir}/themes/ZoroLight/gtk-4.0/

# GNOME Shell theme
install -d -m 0755 %{buildroot}%{_datadir}/gnome-shell/theme/ZoroDeck
install -m 0644 %{SOURCE2}/gnome-shell/gnome-shell.css \
    %{buildroot}%{_datadir}/gnome-shell/theme/ZoroDeck/gnome-shell.css

# Theme index files
cat > %{buildroot}%{_datadir}/themes/ZoroDark/index.theme << 'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=ZoroDark
Comment=Dark theme for Zoro Linux 10
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=ZoroDark
IconTheme=ZoroIcons
CursorTheme=ZoroBlade
MetacityTheme=ZoroDark
EOF

cat > %{buildroot}%{_datadir}/themes/ZoroLight/index.theme << 'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=ZoroLight
Comment=Light theme for Zoro Linux 10
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=ZoroLight
IconTheme=ZoroIcons
CursorTheme=ZoroBlade
MetacityTheme=ZoroLight
EOF

%files
%dir %{_datadir}/themes/ZoroDark
%{_datadir}/themes/ZoroDark/index.theme
%{_datadir}/themes/ZoroDark/gtk-3.0/gtk.css
%{_datadir}/themes/ZoroDark/gtk-4.0/gtk.css
%dir %{_datadir}/themes/ZoroLight
%{_datadir}/themes/ZoroLight/index.theme
%{_datadir}/themes/ZoroLight/gtk-3.0/gtk.css
%{_datadir}/themes/ZoroLight/gtk-4.0/gtk.css
%dir %{_datadir}/gnome-shell/theme/ZoroDeck
%{_datadir}/gnome-shell/theme/ZoroDeck/gnome-shell.css

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release: ZoroDark, ZoroLight GTK themes
- ZoroDeck GNOME Shell theme
