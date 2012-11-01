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

# Set working directory
WDIR="/tmp/spotify"

# ============================================================================ #
# End user editable section                                                    #
# ============================================================================ #

# Check for system type
XBIT=$(uname -m)

# Create and change to working directory
mkdir -p $WDIR
pushd $WDIR

# Check if user is root or in sudo mode
UIC=$(id -u)
if [ "$UIC" != "0" ]
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

# 64-bit OS
if [ "$XBIT" == "x86_64" ]
then
    FNAME=${FNAME}_amd64.deb
    LIBDIR="/usr/lib64"
# 32-bit OS
elif [ "$XBIT" == "i686" ]
then
    FNAME=${FNAME}_i386.deb
    LIBDIR="/usr/lib"
else
    echo "Not Supported"
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
    echo "Spotify .deb package already exists: $WDIR/$FNAME"
fi

# Convert to RPM
echo "Convert .deb to .rpm ..."
echo "(you can safely ignore an error from find during this step)"
alien -k -r $FNAME

# Install Spotify
echo "Install Spotify..."
rpm -i --force --nodeps $WDIR/spotify-client*.rpm

# Create directory for links
SPOTIFY_LIBDIR="$LIBDIR/spotify"
mkdir -p $SPOTIFY_LIBDIR

# Create links to libraries for compatibility
echo "Created symbolic links for Spotify library compatibility..."
SPOTIFY_LIB_DEPS=(libnspr4.so.0d libnss3.so.1d libnssutil3.so.1d libplc4.so.0d libsmime3.so.1d libcrypto.so.0.9.8 libssl.so.0.9.8)
for spotify_lib in ${SPOTIFY_LIB_DEPS[@]}
do
    lib=`echo $spotify_lib | cut -d '.' -f 1`.so
    if [ ! -e $SPOTIFY_LIBDIR/$spotify_lib ]
    then
        ln -s $LIBDIR/$lib $SPOTIFY_LIBDIR/$spotify_lib
        echo "$SPOTIFY_LIBDIR/$spotify_lib -> $LIBDIR/$lib"
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

LD_LIBRARY_PATH=$SPOTIFY_LIBDIR /usr/share/spotify/spotify "\$@"
EOF
chmod 755 /usr/bin/spotify

# Clean up
echo "Clean up working directory..."
rm -f $WDIR/spotify-client*.rpm

echo "Done!"
