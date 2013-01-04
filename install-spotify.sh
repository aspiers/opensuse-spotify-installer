#!/bin/bash
#
# Automate installation of Spotify on openSUSE 12.2
#
# Credits for original version go to arminw on spotify forums:
#
# http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331

SPOTIFY_BIN="/usr/bin/spotify"

POOL_URL="http://repository.spotify.com/pool/non-free/s/spotify"

# Name of file residing within official Spotify repository above
FNAME="spotify-client_0.8.8.323.gd143501.250-1"


# ============================================================================ #
# End user editable section                                                    #
# ============================================================================ #

main () {
    parse_args "$@"

    check_root
    get_libdir

    if [ -z "$uninstall" ]; then
        tempdir=$( mktemp -d /tmp/install-spotify.XXXXXXXXXXX )
        cd "$tempdir"

        install_dependencies
        download_spotify_deb
        convert_to_rpm
        install_spotify_rpm
        create_spotify_libdir
        create_wrapper_script
        clean_up

        echo "Spotify can now be run via $SPOTIFY_BIN - happy listening!"
    else
        uninstall
    fi
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
       $me -u | --uninstall

DEB-NAME is the basename of the upstream .deb package, and defaults to:

  $FNAME
EOF
    exit "$exit_code"
}

parse_args () {
    uninstall=

    while [ $# != 0 ]; do
        case "$1" in
            -h|--help)
                usage 0
                ;;
            -u|--uninstall)
                uninstall=y
                shift
                ;;
            -*)
                usage "Unrecognised option: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    if [ $# -gt 1 ]; then
        usage
    fi

    if [ -n "$1" ]; then
        FNAME=$1
    fi
}

safe_run () {
    if ! "$@"; then
        echo "$* failed! Aborting." >&2
        exit 1
    fi
}

check_root () {
    if [ "$(id -u)" != "0" ]; then
        echo "Script must be run as root; aborting."
        exit 1
    fi
}

get_libdir () {
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

    spotify_libdir="$libdir/spotify"
}
 
install_dependencies () {
    if ! zypper lr -d | \
        egrep -q 'http://download.opensuse.org/repositories/utilities/openSUSE_12.2/? '
    then
        # Add the needed repository
        safe_run zypper ar -f http://download.opensuse.org/repositories/utilities/openSUSE_12.2/ utilities
    fi

    # Refresh repositories
    safe_run zypper refresh

    # Install alien and rpm-build for .deb conversion,
    # libopenssl-devel for /usr/lib64 symlinks, and libpng12 to keep
    # Spotify happy.
    safe_run zypper install -lny alien rpm-build libopenssl-devel libpng12-0
}

download_spotify_deb () {
    if [ ! -e ./$FNAME ]; then
        echo "Downloading Spotify .deb package..."
        safe_run wget $POOL_URL/$FNAME
    else 
    # This should no longer happen now we're using a secure temporary directory.
        echo "Spotify .deb package already exists: $tempdir/$FNAME"
        echo "Skipping download."
    fi
}

convert_to_rpm () {
    echo "Converting .deb to .rpm using alien; this will take a few moments ..."
    echo "(you can safely ignore an error from find during this step)"
    safe_run alien -k -r $FNAME
}

install_spotify_rpm () {
    echo "Install Spotify..."
    safe_run rpm -i --force --nodeps $tempdir/spotify-client*.rpm
}

create_spotify_libdir () {
    safe_run mkdir -p $spotify_libdir

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
            safe_run ln -s $libdir/$lib $spotify_libdir/$spotify_lib
            echo "$spotify_libdir/$spotify_lib -> $libdir/$lib"
        fi
    done
}

create_wrapper_script () {
    echo "Create a wrapper script to include the compatibility libraries..."

    if [ ! -L "$SPOTIFY_BIN" ]; then
        cat <<'EOF' >&2
$SPOTIFY_BIN was not a symlink as expected!
Can't safely remove; aborting.
EOF
        exit 1
    fi
    safe_run rm "$SPOTIFY_BIN"
    cat <<EOF > "$SPOTIFY_BIN"
#!/bin/sh

LD_LIBRARY_PATH=$spotify_libdir /usr/share/spotify/spotify "\$@"
EOF
    safe_run chmod 755 "$SPOTIFY_BIN"
}

uninstall () {
    rpm -qa | grep '^spotify-client' | while read rpm; do
        echo "Removing $rpm rpm ..."
        safe_run rpm -ev "$rpm"
    done

    if [ -e "$spotify_libdir" ]; then
        echo "Removing compatibility libraries ..."
        rm -rf "$spotify_libdir"
    else
        echo "$spotify_libdir did not exist"
    fi

    if [ -e "$SPOTIFY_BIN" ]; then
        echo "Removing wrapper script ..."
        rm -f "$SPOTIFY_BIN"
    else
        echo "$SPOTIFY_BIN did not exist"
    fi

    echo "De-installation done!"
}

clean_up () {
    echo "Clean up working directory..."
    rm -f $tempdir/spotify-client*.{deb,rpm}
    rmdir $tempdir
}

main "$@"
