#!/bin/bash
#
# Automate installation of Spotify on openSUSE 12.2
#
# Credits for original version go to arminw on spotify forums:
#
# http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/td-p/143468

# Name of files residing on Spotify repository
# http://repository.spotify.com/pool/non-free/s/spotify/
FNAME="spotify-client_0.8.4.103.g9cb177b.260-1"

# ============================================================================ #
# End user editable section                                                    #
# ============================================================================ #

# Create and change to working directory
tempdir=$( mktemp -d /tmp/install-spotify.XXXXXXXXXXX )
cd "$tempdir"

# Check if user is root or in sudo mode
if [ "$(id -u)" != "0" ]
then
    echo "Script must be run as root, exiting..."
    exit
fi

# Install alien, needed for .deb to .rpm conversion
install_dependencies()
{
    if ! zypper lr -d | \
        egrep -q 'http://download.opensuse.org/repositories/utilities/openSUSE_12.2/? '
    then
        # Add the needed repository
        zypper ar -f http://download.opensuse.org/repositories/utilities/openSUSE_12.2/ utilities
    fi

    # Refresh repositories
    zypper refresh

    # Install alien for .deb conversion, libpng12
    zypper install -lny alien libpng12-0
}

# Check for parameter
if [ "$1" != "" ]
then
    FNAME=$1
fi

# Check system type
arch=$(arch)
if [ "$arch" == "x86_64" ]
then
    FNAME=${FNAME}_amd64.deb
    libdir="/usr/lib64"
elif [ "$arch" == "i686" ]
then
    FNAME=${FNAME}_i386.deb
    libdir="/usr/lib"
else
    echo "Sorry, $arch architecture isn't supported.  Aborting."
    exit 1
fi
 
# Calls on dependencies installation function
install_dependencies

# Download Spotify .deb package
if [ ! -e ./$FNAME ]
then
    echo "Download Spotify .deb package..."
    wget http://repository.spotify.com/pool/non-free/s/spotify/$FNAME
else 
    # This should no longer happen now we're using a secure temporary directory.
    echo "Spotify .deb package already exists: $tempdir/$FNAME"
    echo "Skipping download."
fi

# Convert to RPM
echo "Converting .deb to .rpm using alien; this will take a few moments ..."
echo "(you can safely ignore an error from find during this step)"
if ! alien -k -r $FNAME; then
    echo "alien conversion failed!  Aborting." >&2
    exit 1
fi

# Install Spotify
echo "Install Spotify..."
if ! rpm -i --force --nodeps $tempdir/spotify-client*.rpm; then
    echo "rpm installation failed!  Aborting." >&2
    exit 1
fi

# Create directory for links
spotify_libdir="$libdir/spotify"
mkdir -p $spotify_libdir

# Create links to libraries for compatibility
echo "Created symbolic links for Spotify library compatibility..."
spotify_lib_deps=(
    libnspr4.so.0d
    libnss3.so.1d
    libnssutil3.so.1d
    libplc4.so.0d
    libsmime3.so.1d
    libcrypto.so.0.9.8
    libssl.so.0.9.8
)
for spotify_lib in ${spotify_lib_deps[@]}
do
    lib=`echo $spotify_lib | cut -d '.' -f 1`.so
    if [ ! -e $spotify_libdir/$spotify_lib ]
    then
        ln -s $libdir/$lib $spotify_libdir/$spotify_lib
        echo "$spotify_libdir/$spotify_lib -> $libdir/$lib"
    fi
done

# Create a wrapper script to include the compatibility-libraries
echo "Create a wrapper script to include the compatibility-libraries..."
if [ ! -L /usr/bin/spotify ]; then
    cat <<'EOF' >&2
/usr/bin/spotify was not a symlink as expected!
Can't safely remove; aborting.
EOF
    exit 1
fi
rm /usr/bin/spotify
cat <<EOF > /usr/bin/spotify
#!/bin/sh

LD_LIBRARY_PATH=$spotify_libdir /usr/share/spotify/spotify "\$@"
EOF
chmod 755 /usr/bin/spotify

# Clean up
echo "Clean up working directory..."
rm -f $tempdir/spotify-client*.{deb,rpm}
rmdir $tempdir

echo "Done!"
