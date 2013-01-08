#
# spec file for package spotify
#
# Copyright (c) 2012 Marguerite Su, Adam Spiers
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

#These refer to the installer, not the main package:
%global commit      2a19e826a23987424220c8af341e2ae8ea2b87a6
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global github_repo https://github.com/leamas/spotify-make/archive/%{commit}

# 0.8.8 has an errant RPATH which was accidentally left in
# http://community.spotify.com/t5/Desktop-Linux/ANNOUNCE-Spotify-0-8-8-for-GNU-Linux/m-p/238118
%global  __arch_install_post  \
         %( echo %{__arch_install_post} | sed '/check-rpaths/d' )

Name:           spotify-client
Version:        0.8.8.323.gd143501.250
Release:        1
License:        Commercial
Summary:        Desktop client for Spotify streaming music service
Url:            http://www.spotify.com/download/previews/
Group:          Productivity/Multimedia/Sound/Players
Source0:        %{github_repo}/spotify-make-%{version}-%{shortcommit}.tar.gz
%ifarch x86_64
Source1: spotify-client_%{version}-%{release}_amd64.deb
%else
Source1: spotify-client_%{version}-%{release}_i386.deb
%endif
NoSource:       0
%if 0%{?suse_version}
BuildRequires:  desktop-file-utils
BuildRequires:  binutils
BuildRequires:  python-devel
BuildRequires:  lsb-release

# The install script will resolve spotify deps against
# these with symlinks if they are present during %install.
BuildRequires:  mozilla-nss
BuildRequires:  mozilla-nspr

Requires:       hicolor-icon-theme
Requires:       zenity
Recommends:     libmp3lame0
%endif

# Not currently tested on Mandriva, but leaving
# these here in case anyone wants to step up and do it :)
%if 0%{?mandriva_version}
Requires:       libnss3
Requires:       libnspr4
Requires:       libopenssl1.0.0
Conflicts:      libopenssl0.9.8
%endif

BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
Spotify is a "Freemium" proprietary, DRM-restricted digital music
service that gives you access to millions of songs.

It includes the following features:

- Custom playlists
- Last.fm integration
- Customized radio dynamically generated to the user's tastes
- Social media integration with Facebook and Twitter
- 3rd-party applications integrated into the client


%prep
%setup -qn spotify-make-%{commit}
cp %{SOURCE1} .

cat >find-requires.sh <<'EOF'
#!/bin/sh

/usr/lib/rpm/find-requires | \
    sed -e 's/lib\(nss3\|nssutil3\|smime3\|plc4\|nspr4\)\.so\.[01]d/lib\1.so/' \
        -e 's/(OPENSSL_0.9.8)//g'
EOF
chmod +x find-requires.sh
%define _use_internal_dependency_generator 0
%define __find_requires %_builddir/spotify-make-%{commit}/find-requires.sh


%build
export PATH=$PATH:/sbin:/usr/sbin
env version=%{version} file=$( basename %{SOURCE1} ) \
    ./configure --prefix=/usr --libdir=%{_libdir} --local


%install
export PATH=$PATH:/sbin:/usr/sbin
make install DESTDIR=%{buildroot}
desktop-file-validate $(DESTDIR)%{_datadir}/applications/spotify.desktop


%post
%desktop_database_post
%icon_theme_cache_post

%postun
%desktop_database_postun
%icon_theme_cache_postun


%files
%defattr(-,root,root)
%doc opt/spotify/spotify-client/licenses.xhtml
%doc opt/spotify/spotify-client/changelog
%{_libdir}/spotify-client
%{_bindir}/spotify
%{_mandir}/man1/spotify.*
%{_datadir}/applications/spotify.desktop
%{_datadir}/icons/hicolor/*/apps/spotify-client.png
%{_datadir}/spotify-client


%changelog
* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org>
- add README

* Sat Jan 05 2013 Adam Spiers <spotify-on-opensuse@adamspiers.org>
- update to 0.8.8 (moved to /opt)
- rename to spotify-client for consistency with original Debian package
- use provided register.sh and unregister.sh
- remove need to conflict with libopenssl0_9_8
- fix automatically generated dependencies
- fix XDG categories
- move dedicated library directory to /opt/spotify/spotify-client/lib
- remove spotify-linux-512x512.png since redistribution probably
  violates Spotify copyright
- fix SPOTIFY_CLEAN_CACHE test
- fix passing of multiple arguments to spotify binary

* Mon Aug 20 2012 Marguerite Su <i@marguerite.su> - 0.8.4.103.g9cb117b.260
- initial version with Spotify App support.
- use libopenssl1_0_0 instead of libopenssl0_9_8 to fix a crash and other linkings ready.
- use wrapper to clear cache manually
