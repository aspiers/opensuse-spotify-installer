#!/bin/bash
#
# Automate installation of Spotify on openSUSE 12.2
#
# Credits for original version go to arminw on spotify forums:
#
# http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331

POOL_URL="http://repository.spotify.com/pool/non-free/s/spotify"

# Name of file residing within official Spotify repository above
FNAME="spotify-client_0.8.4.103.g9cb177b.260-1"


# ============================================================================ #
# End user editable section                                                    #
# ============================================================================ #

main () {
    tempdir=$( mktemp -d /tmp/install-spotify.XXXXXXXXXXX )
    cd "$tempdir"

    parse_args "$@"
    check_root
    check_architecture
    install_dependencies
    download_spotify_deb
    convert_to_rpm
    install_spotify_rpm
    create_spotify_libdir
    create_wrapper_script
    clean_up

    echo "Done!"
}

usage () {
    # Call as: usage [EXITCODE] [USAGE MESSAGE]
    exit_code=1
    if [[ "$1" == [0-9] ]]; then
        exit_code="$1"
        shift
    fi
    if [ -n "$1" ]; then
        echo "$*" >&2
        echo
    fi

    me=`basename $0`

    cat <<EOF >&2
Usage: $me [DEB-NAME]

DEB-NAME is the basename of the upstream .deb package, and defaults to:

  $FNAME
EOF
    exit "$exit_code"
}

parse_args () {
    if [ "$1" == '-h' ] || [ "$1" == '--help' ]; then
        usage 0
    fi

    if [ $# -gt 1 ]; then
        usage
    fi

    if [ -n "$1" ]; then
        FNAME=$1
    fi
}

check_root () {
    if [ "$(id -u)" != "0" ]; then
        echo "Script must be run as root; aborting..."
        exit 1
    fi
}

check_architecture () {
    arch=$(arch)
    if [ "$arch" == "x86_64" ]; then
        FNAME=${FNAME}_amd64.deb
        libdir="/usr/lib64"
    elif [ "$arch" == "i686" ]; then
        FNAME=${FNAME}_i386.deb
        libdir="/usr/lib"
    else
        echo "Sorry, $arch architecture isn't supported.  Aborting."
        exit 1
    fi
}
 
install_dependencies () {
    if ! zypper lr -d | \
        egrep -q 'http://download.opensuse.org/repositories/utilities/openSUSE_12.2/? '
    then
        # Add the needed repository
        zypper ar -f http://download.opensuse.org/repositories/utilities/openSUSE_12.2/ utilities
    fi

    # Refresh repositories
    zypper refresh

    # Install alien for .deb conversion, libopenssl-devel for
    # /usr/lib64 symlinks, and libpng12 to keep Spotify happy.
    zypper install -lny alien libopenssl-devel libpng12-0
}

download_spotify_deb () {
    if [ ! -e ./$FNAME ]; then
        echo "Downloading Spotify .deb package..."
        wget $POOL_URL/$FNAME
    else 
    # This should no longer happen now we're using a secure temporary directory.
        echo "Spotify .deb package already exists: $tempdir/$FNAME"
        echo "Skipping download."
    fi
}

convert_to_rpm () {
    echo "Converting .deb to .rpm using alien; this will take a few moments ..."
    echo "(you can safely ignore an error from find during this step)"
    if ! alien -k -r $FNAME; then
        echo "alien conversion failed!  Aborting." >&2
        exit 1
    fi
}

install_spotify_rpm () {
    echo "Install Spotify..."
    if ! rpm -i --force --nodeps $tempdir/spotify-client*.rpm; then
        echo "rpm installation failed!  Aborting." >&2
        exit 1
    fi
}

create_spotify_libdir () {
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
    for spotify_lib in ${spotify_lib_deps[@]}; do
        lib=`echo $spotify_lib | cut -d '.' -f 1`.so
        if [ ! -e $spotify_libdir/$spotify_lib ]
        then
            ln -s $libdir/$lib $spotify_libdir/$spotify_lib
            echo "$spotify_libdir/$spotify_lib -> $libdir/$lib"
        fi
    done
}

create_wrapper_script () {
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
}

clean_up () {
    echo "Clean up working directory..."
    rm -f $tempdir/spotify-client*.{deb,rpm}
    rmdir $tempdir
}

main "$@"
