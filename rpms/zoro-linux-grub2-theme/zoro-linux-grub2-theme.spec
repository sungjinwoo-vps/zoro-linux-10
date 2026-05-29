%define debug_package %{nil}

Name:           zoro-linux-grub2-theme
Version:        10
Release:        1%{?dist}
Summary:        Zoro Linux GRUB2 bootloader theme
License:        GPLv2
URL:            https://zorolinux.org
BuildArch:      noarch
Requires:       grub2-common

Source0:        theme.txt
Source1:        grub-defaults

%description
Zoro Linux GRUB2 visual theme for the bootloader.
Features a dark green background with the Zoro Linux three-sword logo,
green-highlighted selection bar, and Zoro branding throughout.

Includes custom GRUB2 configuration with Zoro Linux distributor string,
5-second timeout, and graphical terminal mode.

%install
# Install theme files
install -d -m 0755 %{buildroot}/boot/grub2/themes/zorolinux
install -m 0644 %{SOURCE0} %{buildroot}/boot/grub2/themes/zorolinux/theme.txt

# Install GRUB defaults
install -D -m 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/default/grub

%post
# Regenerate GRUB config to apply theme
if [ -x /usr/sbin/grub2-mkconfig ]; then
    grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
fi

%files
%dir /boot/grub2/themes/zorolinux
/boot/grub2/themes/zorolinux/theme.txt
%config(noreplace) %{_sysconfdir}/default/grub

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 10-1
- Initial release of Zoro Linux GRUB2 theme
