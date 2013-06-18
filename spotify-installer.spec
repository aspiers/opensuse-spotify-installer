#
# spec file for package spotify-installer
#
# Copyright (c) 2012 Adam Spiers
#

Name:           spotify-installer
Version:        0.9.0
Release:        1
License:        MIT
Summary:        Installer for Spotify desktop client
Url:            https://github.com/aspiers/opensuse-spotify-installer/
Group:          Productivity/Multimedia/Sound/Players
Source0:        install-spotify.sh
Source1:        README.md
Requires:       sudo
BuildRequires:  python-markdown
BuildArch:      noarch
Recommends:     brp-check-suse

%description
This is an automatic installer for the Spotify desktop client for
Linux, which circumvents the redistribution restrictions on the client
by:

  . Downloading spec file and other support from github.
  - Downloading the .deb from spotify.com.
  - Installing required dependencies.
  - Building an rpm.
  - Installing the rpm.
The process is intended to be as user-friendly as possible.


%prep


%build
markdown_py -o html5 %{SOURCE1} > README.html


%install
install -D -m 755 %{SOURCE0}  %{buildroot}%{_bindir}/install-spotify


%files
%defattr(-,root,root)
%{_bindir}/*
%doc README.html


%changelog
* Fri May 24 2013 Alec Leamas <leamas.alec@gmail.com> - 0.9.0-1
- Simplified version scheme.
- Dropped spec file from package.
- Don't install %%doc files.

* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org> - 0.8.8.323.gd143501.250-2
- update README
- add Requires: sudo

* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org> - 0.8.8.323.gd143501.250-1
- first version
