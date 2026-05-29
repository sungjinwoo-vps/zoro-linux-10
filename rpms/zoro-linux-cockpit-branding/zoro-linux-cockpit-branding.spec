%define debug_package %{nil}

Name:           zoro-linux-cockpit-branding
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux Cockpit web console branding
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       cockpit

Source0:        branding.css
Source1:        override.json

%description
Cockpit web console branding for Zoro Linux 10.
Replaces the default Cockpit login page, sidebar, and header
with Zoro Linux colours, logo, and Forest Green theme.

Login page title: "Zoro Linux — System Console"

%install
install -d -m 0755 %{buildroot}%{_datadir}/cockpit/branding/zorolinux
install -m 0644 %{SOURCE0} %{buildroot}%{_datadir}/cockpit/branding/zorolinux/branding.css
install -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/cockpit/branding/zorolinux/override.json

# Copy logo if available
install -d -m 0755 %{buildroot}%{_datadir}/cockpit/branding/zorolinux

%files
%dir %{_datadir}/cockpit/branding/zorolinux
%{_datadir}/cockpit/branding/zorolinux/branding.css
%{_datadir}/cockpit/branding/zorolinux/override.json

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of Cockpit branding for Zoro Linux
