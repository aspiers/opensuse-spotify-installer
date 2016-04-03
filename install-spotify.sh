#!/bin/bash
#
# Automate installation of Spotify on openSUSE 12.2
#
# Credits for original version go to arminw on spotify forums:
#
# http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331

POOL_URL="http://repository.spotify.com/pool/non-free/s/spotify-client"

# We prefer to keep the amount of code running as root to an absolute
# minimum, but spotify-installer.spec can't install to a user's home
# directory, so the spec file goes in /usr/src/packages even though
# the rest of the rpmbuild stuff lives in $HOME.
RPM_TOPDIR="$HOME/rpmbuild"
RPM_SOURCE_DIR="$RPM_TOPDIR/SOURCES"
RPM_SPEC_DIR="."
RPM_NAME="spotify-client"

ISSUE_TRACKER_URL="https://github.com/cornguo/opensuse-spotify-installer/issues"

# get system architecture
ARCH=$(arch)
OSNAME=`cat /etc/os-release | grep "^NAME=" | awk -F '=' '{print $2}' | tr -d '"' | sed 's/ /_/g'`
OSVER=`cat /etc/os-release | grep "^VERSION=" | awk -F '=' '{print $2}' | awk -F ' ' '{print $1}' | tr -d '"'`

main () {
    parse_args "$@"

    check_non_root

    if [ -z "$uninstall" ]; then
        if get_params; then
            if check_not_installed; then
                progress "Creating spec file from template..."
                SPEC_TEMPLATE="$RPM_SPEC_DIR/${RPM_NAME}.spec"
                safe_run cat $SPEC_TEMPLATE | sed "s/VERTOKEN/$VERSION/g" | sed "s/RELTOKEN/$RELEASE/g" | sed "s/DEB_AMD64/$FILE_AMD64/g" | sed "s/DEB_I386/$FILE_I386/g" > /tmp/$RPM_NAME.spec
                echo
                safe_run mkdir -p "$RPM_TOPDIR"/{BUILD,BUILDROOT,SPECS,SOURCES,SRPMS,RPMS/{i586,x86_64}}
                install_rpm_build
                echo
                download_spotify_deb
                echo
                build_rpm
                echo
                install_rpm
            fi
            echo
            maybe_install_libmp3lame0
            echo
            SPOTIFY_BIN=`which spotify`
            progress "Spotify can now be run via $SPOTIFY_BIN - happy listening!"
        fi
    else
        uninstall
    fi
}

get_params() {
    # get current online version
    echo "Getting version info..."
    FILE_LIST=`wget --progress=bar -qO - $POOL_URL | grep deb | 
sed 's/.*<a href="\(.*.deb\)".*/\1/g'`
    FILE_AMD64=`echo "$FILE_LIST" | grep "amd64" | sort | tail -n 1`
    FILE_I386=`echo "$FILE_LIST" | grep "i386" | sort | tail -n 1`

    INFO_AMD64=`echo "$FILE_AMD64" | awk -F '_' '{print $2}' | sed 's/-/./g'`
    VER_AMD64=`echo "$INFO_AMD64" | rev | cut -d. -f2- | rev`
    RELEASE_AMD64=`echo "$INFO_AMD64" | rev | cut -d. -f1 | rev`

    INFO_I386=`echo "$FILE_I386" | awk -F '_' '{print $2}' | sed 's/-/./g'`
    VER_I386=`echo "$INFO_I386" | rev | cut -d. -f2- | rev`
    RELEASE_I386=`echo "$INFO_I386" | rev | cut -d. -f1 | rev`

    # decide version by arch
    if [ "$ARCH" == "x86_64" ]; then
        DEB=$FILE_AMD64
        RPMARCH="x86_64"
        VERSION=$VER_AMD64
        RELEASE=$RELEASE_AMD64
    elif [ "$ARCH" == "i686" ]; then
        DEB=$FILE_I386
        RPMARCH="i586"
        VERSION=$VER_I386
        RELEASE=$RELEASE_I386
    fi

    # Name of file residing within official Spotify repository above
    FILE_NAME="spotify-client"
    BASENAME="${FILE_NAME}_$VERSION"

    # get current installed version
    CURRENT=`rpm -q "$RPM_NAME"`
    VER_CURRENT=`echo "$CURRENT" | awk -F '-' '{print $3}'`
    RELEASE_CURRENT=`echo "$CURRENT" | awk -F '-' '{print $4}' | awk -F '.' '{print $1}'`
    ARCH_CURRENT=`echo "$CURRENT" | awk -F '-' '{print $4}' | awk -F '.' '{print $2}'`
    if [ -z $VER_CURRENT ]; then
        VER_CURRENT="(not installed)"
    fi

    progress "Current version = $VER_CURRENT, release = $RELEASE_CURRENT, arch = $ARCH_CURRENT"
    progress "Online version  = $VERSION, release = $RELEASE, arch = $RPMARCH"

    PROMPTMSG="Upgrade?"

    # if is the latest version, echo message
    if [ "$VER_CURRENT" == "$VERSION" -a "$RELEASE_CURRENT" == "$RELEASE" ]; then
        warn "Current installed version is the latest version."
        PROMPTMSG="Reinstall?"
        echo
    fi

    # ask if user want to reinstall
    if [ "(not installed)" != "$VER_CURRENT" ]; then
        if [ "$ARCH" != "x86_64" -a "$ARCH" != "i686" ]; then
            fatal "
Sorry, $ARCH architecture isn't supported.  If you think this is a
mistake, please consider filing a bug at:

    $ISSUE_TRACKER_URL

Aborting."
        else
            echo -n "$PROMPTMSG y/n> "
            read answer
            case "$answer" in
                y|yes|Y|YES)
                    uninstall
                    ;;
                *)
                    echo
                    return -1
                    ;;
            esac
        fi
    fi

    echo
    return 0
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
Usage: $me
       $me -u | --uninstall
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
        BASENAME=$1
    fi
}

progress () { tput bold; tput setaf 2; echo     "$*"; tput sgr0; }
warn     () { tput bold; tput setaf 3; echo >&2 "$*"; tput sgr0; }
error    () { tput bold; tput setaf 1; echo >&2 "$*"; tput sgr0; }
fatal    () { error "$@"; echo; exit 1; }

safe_run () {
    if ! "$@"; then
        fatal "$* failed! Aborting." >&2
        exit 1
    fi
}

check_non_root () {
    if [ "$(id -u)" = "0" ]; then
        fatal "\
Please run this script non-root, it's a bit safer that way.
It will use sudo for commands which need root.  Aborting."
    fi
}

maybe_install_libmp3lame0 () {
    if ! rpm -q libmp3lame0 >/dev/null; then
        warn "\
WARNING: You do not have libmp3lame0 installed, so playback of local
mp3 files will not work.  Would you like me to install this from
Packman now?"
        echo -n "Type y/n> "
        read answer
        case "$answer" in
            y|yes|Y|YES)
                echo
                install_libmp3lame0
                ;;
        esac
    fi
}

install_rpm_build () {
    if rpm -q rpm-build >/dev/null; then
        progress "rpm-build is already installed."
    else
        safe_run sudo zypper -n install -lny rpm-build
    fi
}

install_libmp3lame0 () {
    if safe_run zypper lr -d | grep -iq 'packman'; then
        progress "Packman repository is already configured - good :)"
    else
        safe_run sudo zypper ar -f http://packman.inode.at/suse/${OSNAME}_${OSVER}/packman.repo
        progress "Added Packman repository."
    fi

    echo
    safe_run sudo zypper -n --gpg-auto-import-keys in -l libmp3lame0
    echo
    progress "Installed libmp3lame0."
}

check_not_installed () {
    if rpm -q "$RPM_NAME" >/dev/null; then
        warn "$RPM_NAME is already installed!  If you want to re-install,
please uninstall first via:

    $0 -u"
        return 1
    else
        return 0
    fi
}

download_spotify_deb () {
    RPM_DIR="$RPM_TOPDIR/RPMS/$RPMARCH"

    dest="$RPM_SOURCE_DIR/$DEB"
    if [ ! -e "$dest" ]; then
        echo "Downloading Spotify .deb package ..."
        safe_run wget --progress=bar -qO "$dest" "$POOL_URL/$DEB"
        progress ".deb downloaded."
    else
        progress "Spotify .deb package already exists:"
        echo
        echo "  ${dest/$HOME/~}"
        echo
        echo "Skipping download."
    fi
}

build_rpm () {
    echo "About to build $RPM_NAME rpm; please be patient ..."
    echo
    sleep 3
    safe_run rpmbuild -ba "/tmp/$RPM_NAME.spec"

    rpm="$RPM_DIR/${RPM_NAME}-${VERSION}-${RELEASE}.$RPMARCH.rpm"

    if ! [ -e "$rpm" ]; then
        fatal "
rpmbuild failed :-(  Please consider filing a bug at:

    $ISSUE_TRACKER_URL"
    fi

    rm -f /tmp/$RPM_NAME.spec

    echo
    progress "rpm successfully built!"
}

install_rpm () {
    echo "Installing Spotify from the rpm we just built ..."
    safe_run sudo zypper in "$rpm"

    if ! rpm -q "$RPM_NAME" >/dev/null; then
        error "Failed to install $rpm :-("
        error "Please consider filing a bug at:

    $ISSUE_TRACKER_URL"
    fi
}

uninstall () {
    if rpm -q "$RPM_NAME" >/dev/null; then
        echo "Removing $RPM_NAME rpm ..."
        safe_run sudo rpm -ev "$RPM_NAME"
        progress "De-installation done!"
    else
        warn "$RPM_NAME was not installed; nothing to uninstall."
    fi
}

main "$@"
