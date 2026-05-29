%define debug_package %{nil}

Name:           zoro-fetch
Version:        1.0.0
Release:        1%{?dist}
Summary:        Zoro Linux system information display tool
License:        GPLv2
URL:            https://zorolinux.org
BuildRequires:  golang >= 1.22

Source0:        src/
Source1:        zoro-fetch.sh
Source2:        zoro-fetch.1

%description
zoro-fetch is a custom neofetch/fastfetch replacement for Zoro Linux 10.
Displays system information with Zoro-themed ASCII art in the terminal.
Written in Go for fast, single-binary deployment.

%prep
cp -a %{SOURCE0} src

%build
cd src
go build -ldflags="-s -w" -o zoro-fetch .

%install
install -D -m 0755 src/zoro-fetch %{buildroot}%{_bindir}/zoro-fetch
install -D -m 0644 %{SOURCE1} %{buildroot}%{_sysconfdir}/profile.d/zoro-fetch.sh
install -D -m 0644 %{SOURCE2} %{buildroot}%{_mandir}/man1/zoro-fetch.1

%files
%{_bindir}/zoro-fetch
%config(noreplace) %{_sysconfdir}/profile.d/zoro-fetch.sh
%{_mandir}/man1/zoro-fetch.1*

%changelog
* %(date '+%a %b %d %Y') Zoro Linux Build System <build@zorolinux.org> - 1.0.0-1
- Initial release of zoro-fetch
