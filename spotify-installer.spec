#
# spec file for package spotify-installer
#
# Copyright (c) 2012 Adam Spiers
#

Name:           spotify-installer
Version:        0.9.11.27.g2b1a638.81
Release:        1
License:        MIT
Summary:        Installer for Spotify desktop client
Url:            https://github.com/aspiers/opensuse-spotify-installer/
Group:          Productivity/Multimedia/Sound/Players
Source0:        spotify-client.spec
Source1:        install-spotify.sh
Source2:        README.md
Requires:       sudo
BuildRequires:  python-markdown
BuildArch:      noarch
Recommends:     brp-check-suse

%define specdir /usr/src/packages/SPECS

%description
This is an automatic installer for the Spotify desktop client for
Linux, which circumvents the redistribution restrictions on the client
by:

  - downloading the .deb from spotify.com
  - installing required dependencies
  - building an rpm
  - installing the rpm

The process is intended to be as user-friendly as possible.

%prep

%build
markdown_py -o html5 %{SOURCE2} > README.html

%install
install -D -m 644 %{SOURCE0}  %{buildroot}%{specdir}/spotify-client.spec
install -D -m 755 %{SOURCE1}  %{buildroot}%{_bindir}/install-spotify
install -d                    %{buildroot}%{_docdir}/%{name}
install -D -m 755 README.html %{buildroot}%{_docdir}/%{name}

%files
%defattr(-,root,root)
%{specdir}/*
%{_bindir}/*
%doc README.html

%changelog
* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org> - 0.8.8.323.gd143501.250-2
- update README
- add Requires: sudo

* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org> - 0.8.8.323.gd143501.250-1
- first version
