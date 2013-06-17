#!/bin/bash
#
# Automate installation of Spotify on openSUSE 12.2
#
# Will download and use stuff from the spotify-make and
# opensuse-spotify-installer github repos. Set MAKE_TARBALL and
# and/or INST_TARBALL to change location from the default
#
# Credits for original version go to arminw on spotify forums:
#
# http://community.spotify.com/t5/Desktop-Linux/Segfault-on-opensuse-12-2/m-p/161048/highlight/true#M1331


INST_REPO=https://github.com/aspiers/opensuse-spotify-installer/tarball/master
INST_TARBALL=${INST_TARBALL:-$INST_REPO/opensuse-spotify-installer.tar.gz}

SPOTIFY_MAKE_SOURCE=leamas
MAKE_REPO=https://github.com/$SPOTIFY_MAKE_SOURCE/spotify-make/tarball/master
MAKE_TARBALL=${MAKE_TARBALL:-$MAKE_REPO/spotify-make.tar.gz}

VERSION="0.9.1.55.gbdd3b79.203"

RPM_NAME="spotify-client"

ISSUE_TRACKER_URL="https://github.com/aspiers/opensuse-spotify-installer/issues"

main () {
    parse_args "$@"
    check_non_root
    if [ -n "$uninstall" ]; then
        uninstall
        exit 0
    elif check_installed; then
        exit 0
    fi

    install_rpm_build
    install_rpmdevtools
    setup_build_env

    SOURCES="$(rpm --eval %_sourcedir)"
    progress "Downloading sources..."
    download_installer "$SOURCES"
    download_spotify_make "$SOURCES"
    download_debs "$SOURCES/$SPOTIFY_MAKE_SOURCE"-spotify-make-* "$SOURCES"

    install_builddeps "$SOURCES"
    build_rpm "$SOURCES/$RPM_NAME.spec"
    install_rpm
    echo
    maybe_install_libmp3lame0
    echo
    progress "Run spotify via /usr/bin/spotify or menu - happy listening!"
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
}

progress () { tput bold; tput setaf 2; echo     "$*"; tput sgr0; }
warn     () { tput bold; tput setaf 3; echo >&2 "$*"; tput sgr0; }
error    () { tput bold; tput setaf 1; echo >&2 "$*"; tput sgr0; }
fatal    () { error "$@"; exit 1; }

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
Packman now?
"
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

install_rpmdevtools () {
    if rpm -q rpmdevtools >/dev/null; then
        progress "rpmdevtools is already installed."
        return
    fi

    local release=$(lsb_release -sr)
    safe_run sudo zypper -np \
       "http://download.opensuse.org/repositories/devel:/tools/openSUSE_${release}/" \
        install osc rpmdevtools
}

setup_build_env() {
    [ -w "$(rpm --eval %_sourcedir)" ] || {
        progress "Installing personal build environment"
        rpmdev-setuptree
    }
}

download_installer() {
    cd "$1"
    rm -rf opensuse-spotify-installer-*
    wget -qnc -O spotify-installer.tar.gz "$INST_TARBALL" || :
    tar xzf  spotify-installer.tar.gz
    cp *-opensuse-spotify-installer-*/* .
    rpmdev-spectool -g --source 0  spotify-client.spec
    progress "Installer downloaded"
}

download_spotify_make() {
    cd "$1"
    rm -rf ${SPOTIFY_MAKE_SOURCE}-spotify-make-* spotify-make.tar.gz
    wget -qnc -O spotify-make.tar.gz "$MAKE_TARBALL" || :
    tar xzf spotify-make.tar.gz
    progress "Spotify-make downloaded"
}

download_debs() {
    cd "$1"
    ./configure --user
    make download-all
    cp *.deb "$2"
    progress "Spotify .deb files downloaded"
}

install_libmp3lame0 () {
    local release=$(lsb_release -sr)
    safe_run sudo zypper -n --gpg-auto-import-keys \
       -p "http://packman.inode.at/suse/${release}/Essentials" \
       install -l libmp3lame0
    progress "Installed libmp3lame0."
}

check_installed () {
    if rpm -q "$RPM_NAME" >/dev/null; then
        warn "$RPM_NAME is already installed!  If you want to re-install,
please uninstall first via:

    $0 -u"
        return 0
    else
        return 1
    fi
}

rpm_path () {
    rpmdir=$( rpm --eval %_rpmdir )
    arch=$( LANG=C rpm --showrc | awk '/^build arch/ {print $4}' )
    echo "$rpmdir/$arch/${RPM_NAME}-${VERSION}-1.$arch.rpm"
}

install_builddeps () {
    cd "$1"
    safe_run rpmbuild -bs --nodeps spotify-client.spec
    srpm=$(rpm --eval %_srcrpmdir)/${RPM_NAME}-${VERSION}-1.src.rpm
    sudo zypper si -d $srpm  || :
}

build_rpm () {
    spec=$1
    progress "About to build $RPM_NAME rpm; please be patient ..."
    QA_RPATHS=$((0x10|0x08)) rpmbuild --quiet -bb $spec
    if ! [ -e "$( rpm_path )" ]; then
        fatal "
rpmbuild failed: Can't find $( rpm_path )
Please consider filing a bug at:

    $ISSUE_TRACKER_URL
"
    fi

    echo
    progress "rpm successfully built!"
}

install_rpm () {
    echo "Installing Spotify from the rpm we just built ..."
    safe_run sudo zypper -n in $( rpm_path )

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

err_trap() {
    trap '' EXIT ERR
    trap - EXIT ERR
    local err=$1
    local line=$2
    local command=$3
    echo '-----'
    echo "ERROR: line $line: Command \"$command\" exited with status: $err"
    echo "Aborting"
}

trap 'err_trap $? $LINENO "$BASH_COMMAND"' ERR
set -e -E
main "$@"
