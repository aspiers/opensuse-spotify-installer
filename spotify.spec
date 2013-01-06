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

Name:           spotify-client
Version:        0.8.8.323.gd143501.250
Release:        1
License:        Commercial
Summary:        Desktop client for Spotify streaming music service
Url:            http://www.spotify.com/download/previews/
Group:          Productivity/Multimedia/Sound/Players
%ifarch x86_64
Source0: spotify-client_%{version}-%{release}_amd64.deb
%else
Source0: spotify-client_%{version}-%{release}_i386.deb
%endif
NoSource:       0
%if 0%{?suse_version}
Requires:       mozilla-nss
Requires:       mozilla-nspr
Requires:       libopenssl1_0_0
Requires:       libpng12-0
Recommends:     libmp3lame0
%endif

# not currently tested on Fedora or Mandriva, but leaving
# these here in case anyone wants to step up and do it :)
%if 0%{?fedora_version}
Requires:       nss
Requires:       nspr
Requires:       openssl >= 1.0.0
%endif
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
%setup -T -c %{name}-%{version}
# unpack deb
ar -x %{SOURCE0}
# unpack data
tar -xzf data.tar.gz
# remove used files
rm {control,data}.tar.gz debian-binary

%define _use_internal_dependency_generator 0
%define __find_requires %_builddir/%{name}-%{version}/find-requires.sh
cat >%__find_requires <<'EOF'
#!/bin/sh

/usr/lib/rpm/find-requires | \
    sed -e 's/lib\(nss3\|nssutil3\|smime3\|plc4\|nspr4\)\.so\.[01]d/lib\1.so/
            /lib\(crypto\|ssl\)\.so/d'
EOF
chmod +x %__find_requires

%build
# no need to build

%install
mv opt %{buildroot}

%define spotifydir /opt/spotify/spotify-client
%define spotifylibdir %spotifydir/lib

# Fix spotify.desktop file:
# - trailing semi-colon is required for fields with multiple values
#   http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#basic-format
desktop=%{buildroot}%{spotifydir}/spotify.desktop
sed -i 's/^\(MimeType=.*\);?$/\1;/i ;
        s/^Categories=/Categories=AudioVideo;Music;Player;Jukebox;/' $desktop

# http://en.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros#.25suse_update_desktop_file
# http://en.opensuse.org/openSUSE:Packaging_desktop_menu_categories#Multimedia
#%suse_update_desktop_file $desktop

mkdir -p %{buildroot}%{_docdir}/%{name}
mv usr/share/doc/spotify-client/* %{buildroot}%{_docdir}/%{name}/

# fix libraries
mkdir -p %{buildroot}%{spotifylibdir}
ln -sf ../libcef.so %{buildroot}%{spotifylibdir}/libcef.so

# install binary wrapper
mkdir -p %{buildroot}%{_bindir}
wrapper="%{buildroot}%{_bindir}/spotify"
cat >"$wrapper" <<'EOF'
#!/bin/sh

if [ -n "$SPOTIFY_CLEAN_CACHE" ]; then
    echo
    echo -n "Cleaning spotify cache ... "
    rm -rf ~/.cache/spotify
    echo "done."
fi

cd %{spotifydir}
LD_LIBRARY_PATH=%{spotifylibdir} ./spotify "$@"
EOF

chmod +x "$wrapper"

# link dependencies
mkdir -p %{buildroot}%{_libdir}
ln -sf /%{_lib}/libcrypto.so.1.0.0 %{buildroot}%{spotifylibdir}/libcrypto.so.0.9.8
ln -sf /%{_lib}/libssl.so.1.0.0 %{buildroot}%{spotifylibdir}/libssl.so.0.9.8
libs=(
    libnss3.so.1d \
    libnssutil3.so.1d \
    libsmime3.so.1d \
    libplc4.so.0d \
    libnspr4.so.0d
)
for lib in "${libs[@]}"; do
    ln -sf %{_libdir}/${lib%.[01]d} %{buildroot}%{spotifylibdir}/$lib
done

# 0.8.8 has an errant RPATH which was accidentally left in
# http://community.spotify.com/t5/Desktop-Linux/ANNOUNCE-Spotify-0-8-8-for-GNU-Linux/m-p/238118/highlight/true#M1867
export NO_BRP_CHECK_RPATH=true

%post
/sbin/ldconfig

cd %{spotifydir}
./register.sh
#%desktop_database_post
#%icon_theme_cache_post

%preun
if [ "$1" = 0 ]; then
    cd %{spotifydir}
    ./unregister.sh
fi

%postun
if [ "$1" = 0 ]; then
    /sbin/ldconfig
fi
#%desktop_database_postun
#%icon_theme_cache_postun

%files
%defattr(-,root,root)
%spotifydir
%doc %{_docdir}/%{name}
%{_bindir}/spotify
#%{_datadir}/applications/spotify.desktop

%changelog
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
