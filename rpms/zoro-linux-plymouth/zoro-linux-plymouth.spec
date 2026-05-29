%define debug_package %{nil}

Name:           zoro-linux-plymouth
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux Plymouth boot animation theme
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       plymouth
Requires:       plymouth-scripts

Source0:        zorolinux.plymouth
Source1:        zorolinux.script

%description
Plymouth boot splash theme for Zoro Linux 10 (Santoryu Edition).
Features a three-blade logo animation — three swords assemble from three
directions, converging at the centre. The progress bar uses a green fill
with a gold glow effect on completion.

Animation style: disciplined, sharp, and precise — like Zoro's Santoryu.

%install
install -d -m 0755 %{buildroot}%{_datadir}/plymouth/themes/zorolinux
install -m 0644 %{SOURCE0} %{buildroot}%{_datadir}/plymouth/themes/zorolinux/zorolinux.plymouth
install -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/plymouth/themes/zorolinux/zorolinux.script

%post
# Set as default Plymouth theme
plymouth-set-default-theme zorolinux 2>/dev/null || true

# Rebuild initramfs with new theme
if [ -x /usr/bin/dracut ]; then
    dracut -f 2>/dev/null || true
fi

%postun
if [ $1 -eq 0 ]; then
    # On uninstall, revert to default theme
    plymouth-set-default-theme details 2>/dev/null || true
fi

%files
%dir %{_datadir}/plymouth/themes/zorolinux
%{_datadir}/plymouth/themes/zorolinux/zorolinux.plymouth
%{_datadir}/plymouth/themes/zorolinux/zorolinux.script

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of Zoro Linux Plymouth theme
- Three-blade assembly animation
- Green progress bar with gold completion glow
