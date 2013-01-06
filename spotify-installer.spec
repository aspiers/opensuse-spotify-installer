#
# spec file for package spotify-installer
#
# Copyright (c) 2012 Adam Spiers
#

Name:           spotify-installer
Version:        0.8.8.323.gd143501.250
Release:        1
License:        MIT
Summary:        Installer for Spotify desktop client
Url:            https://github.com/aspiers/opensuse-spotify-installer/
Group:          Productivity/Multimedia/Sound/Players
Source0:        spotify.spec
Source1:        install-spotify.sh
BuildArch:      noarch

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

%install
install -D -m 644 %{SOURCE0} %{buildroot}%{specdir}/spotify.spec
install -D -m 755 %{SOURCE1} %{buildroot}%{_bindir}/install-spotify

%files
%defattr(-,root,root)
%{specdir}/*
%{_bindir}/*

%changelog
* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org>
- first version
