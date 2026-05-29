%define debug_package %{nil}

Name:           zoro-linux-welcome
Version:        1.0.0
Release:        1%{?dist}
Summary:        Zoro Linux first-run welcome application
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       python3
Requires:       python3-gobject
Requires:       gtk4
Requires:       libadwaita

Source0:        zoro-welcome.py
Source1:        zoro-welcome.desktop

%description
First-run welcome application for Zoro Linux 10 (Santoryu Edition).
A GTK4/Libadwaita wizard that shows on first login to introduce new users
to Zoro Linux features, repositories, themes, and documentation.

Pages: Welcome, What's New, Enable Extras Repo, Themes, Documentation.

%install
install -D -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/zoro-welcome
install -D -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/applications/zoro-welcome.desktop
install -d -m 0755 %{buildroot}%{_sysconfdir}/skel/.config/autostart
install -m 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/skel/.config/autostart/zoro-welcome.desktop

%files
%{_bindir}/zoro-welcome
%{_datadir}/applications/zoro-welcome.desktop
%{_sysconfdir}/skel/.config/autostart/zoro-welcome.desktop

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 1.0.0-1
- Initial release of zoro-welcome
