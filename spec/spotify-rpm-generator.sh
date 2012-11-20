#!/bin/sh

# Author: Marguerite Su <i@marguerite.su>
# License: GPL-3.0
# Version: 1.0
# Descritpion: Shell Scripts used to build and install Spotify standard RPM for openSUSE.

# need root permission

if [[ $UID -ne 0 ]]
then
        echo "Only root can run this script!"
        exit 1
fi

# check if we have 'rpmbuild' package installed, if not then install it.

if rpm -qa rpm-build; then
	# already installed
else
	zypper install --no-refresh rpm-build # 'rpm-build' is in oss, so no need to refresh that long.
fi


# prepare for the build environment.

# download specfile from github
pushd /usr/src/package/SPECS/
wget https://raw.github.com/aspiers/opensuse-spotify-installer/master/spec/spotify.spec
popd

cd /usr/src/packages/SOURCES/

echo "What is your architecture? 1.) x86_64 2.) i586 : (1 or 2)"
read ARCH

case $ARCH in
	1)	
		echo "Bingo! Downloading..."
		wget http://repository.spotify.com/pool/non-free/s/spotify/spotify-client_0.8.4.103.g9cb177b.260-1_amd64.deb
		;;
	2)
		echo "Bingo! Downloading..."
		wget http://repository.spotify.com/pool/non-free/s/spotify/spotify-client_0.8.4.103.g9cb177b.260-1_i386.deb
		;;
	*)
		echo "You must select an architecture! See if you have a /usr/lib64 directory."
		exit 1
		;;
esac

# build

echo "Building..."

cd ../SPECS/
rpmbuild -ba spotify.spec

echo "Build done! Cleaning..."

# clean

echo "Input your NORMAL username :"
read NORMAL_USER

## copy generated rpm
if [ $ARCH == '1' ]; then
	cp -r ../RPMS/x86_64/*.rpm /home/$NORMAL_USER/
else
	cp -r ../RPMS/i586/*.rpm /home/$NORMAL_USER/
fi

## real clean
rm -rf /usr/src/packages/SOURCES/*
rm -rf /usr/src/packages/BUILD/*
rm -rf /usr/src/packages/BUILDROOT/*
rm -rf /usr/src/packages/RPM/i586/*
rm -rf /usr/src/packages/RPM/x86_64/*
rm -rf /usr/src/packages/SRPM/*
rm -rf /usr/src/packages/SPECS/*

# install

echo "Installing..."

rpm -ivh --force --nodeps /home/$NORMAL_USER/spotify-*.rpm

echo "Congrats! Installation finished.\n
We put the generated RPM under your home.\n
Next time you can use `sudo rpm -ivh --force --nodeps spotify-*.rpm` or\n
`sudo zypper install --no-refresh --force-resolution` to install it."

# quit

echo "Quiting..."

exit 0

