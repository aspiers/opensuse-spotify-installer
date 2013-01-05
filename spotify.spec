#
# spec file for package spotify
#
# Copyright (c) 2012 Marguerite Su.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via 
# http://forums.opensuse.org/english/get-technical-help-here/multimedia/443186-spotify-linux-version-opensuse.html
#

Name:           spotify
Version:	0.8.4.103
Release:	g9cb177b.260
License:	Any Commercial
Summary:	A world of Music
Url:	http://repository.spotify.com/pool/non-free/s/spotify
Group:	Productivity/Multimedia/Sound/Players
%ifarch x86_64
Source0: %{name}-client_%{version}.%{release}-1_amd64.deb
%else
Source0: %{name}-client_%{version}.%{release}-1_i386.deb
%endif
NoSource:	0
%if 0%{?suse_version}
Requires:	mozilla-nss
Requires:	mozilla-nspr
# can't use 0.9.8, it crashes spotify.
Requires:	libopenssl1_0_0
Conflicts:	libopenssl0_9_8
%endif
%if 0%{?fedora_version}
Requires:	nss
Requires:	nspr
Requires:	openssl	>= 1.0.0
%endif
%if 0%{?mandriva_version}
Requires:	libnss3
Requires:	libnspr4
Requires:	libopenssl1.0.0
Conflicts:	libopenssl0.9.8
%endif
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
Spotify is a new way to listen to music.
Millions of tracks, any time you like. Just search for it in Spotify, then play it. Just help yourself to whatever you want, whenever you want it.

%prep
%setup -T -c %{name}-%{version}
# drag deb here
cp -r %{SOURCE0} ./
# unpack deb
ar -x *.deb
# remove used deb
rm -rf *.deb
# unpack data
tar -xzf data.tar.gz
# remove used files
rm -rf *.gz
rm -rf debian-binary

%build
# no need to build

%install
mv usr %{buildroot}
# use wrapper instead
rm -rf %{buildroot}%{_bindir}/%{name}

# fix desktop
sed -i "s/AudioVideo/AudioVideo;/" %{buildroot}%{_datadir}/applications/%{name}.desktop
sed -i "s/x-scheme-handler\/spotify/x-scheme-handler\/spotify;/" %{buildroot}%{_datadir}/applications/%{name}.desktop

# fix doc
mkdir -p %{buildroot}%{_docdir}/%{name}
mv %{buildroot}%{_datadir}/doc/%{name}-client/* %{buildroot}%{_docdir}/%{name}/
rm -rf %{buildroot}%{_datadir}/doc/%{name}-client/

# fix libraries
mkdir -p %{buildroot}%{_libdir}/spotify/
mv %{buildroot}%{_datadir}/spotify/libcef.so %{buildroot}%{_libdir}/spotify/
ln -sf %{_libdir}/spotify/libcef.so %{buildroot}%{_datadir}/spotify/libcef.so

# install binary wrapper
pushd %{buildroot}%{_bindir}
cat > %{name} << 'EOF'
#!/bin/sh
if [ $?SPOTIFY_CLEAN_CACHE ]; then
   echo                 
   echo Cleaning spotify cache
   rm -r ~/.cache/spotify
   echo                         
fi

cd /usr/share/spotify/
LD_LIBRARY_PATH=%{_libdir}/spotify ./spotify "$*"

EOF
chmod +x %{name}
popd

# link dependencies
%ifarch x86_64
ln -sf /lib64/libcrypto.so.1.0.0 %{buildroot}%{_libdir}/libcrypto.so.0.9.8
ln -sf /lib64/libssl.so.1.0.0 %{buildroot}%{_libdir}/libssl.so.0.9.8
%else
ln -sf /lib/libcrypto.so.1.0.0 %{buildroot}%{_libdir}/libcrypto.so.0.9.8
ln -sf /lib/libssl.so.1.0.0 %{buildroot}%{_libdir}/libssl.so.0.9.8
%endif
ln -sf %{_libdir}/libnss3.so %{buildroot}%{_libdir}/libnss3.so.1d
ln -sf %{_libdir}/libnssutil3.so %{buildroot}%{_libdir}/libnssutil3.so.1d
ln -sf %{_libdir}/libsmime3.so %{buildroot}%{_libdir}/libsmime3.so.1d
ln -sf %{_libdir}/libplc4.so %{buildroot}%{_libdir}/libplc4.so.0d
ln -sf %{_libdir}/libnspr4.so %{buildroot}%{_libdir}/libnspr4.so.0d

export NO_BRP_CHECK_RPATH=true

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%defattr(-,root,root)
%doc %{_docdir}/%{name}
%{_bindir}/spotify
%{_libdir}/spotify/
%{_libdir}/libcrypto.so.0.9.8
%{_libdir}/libssl.so.0.9.8
%{_libdir}/libnss3.so.1d
%{_libdir}/libnssutil3.so.1d
%{_libdir}/libsmime3.so.1d
%{_libdir}/libplc4.so.0d
%{_libdir}/libnspr4.so.0d
%{_datadir}/applications/spotify.desktop
%{_datadir}/spotify
%{_datadir}/pixmaps/spotify-linux-512x512.png

%changelog
* Mon Aug 20 2012 Marguerite Su <i@marguerite.su> - 0.8.4.103.g9cb117b.260
- initial version with Spotify App support.
- use libopenssl1_0_0 instead of libopenssl0_9_8 to fix a crash and other linkings ready.
- use wrapper to clear cache manually

