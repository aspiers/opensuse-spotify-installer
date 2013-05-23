#!/bin/bash

path=$0
[[ "$path" == /* ]] || path=$PWD/$path
cd ${path%/*}

spotify=/usr/bin/spotify

if [ -n "$SPOTIFY_CLEAN_CACHE" ]; then
    echo
    echo -n "Cleaning spotify cache ... "
    rm -rf ~/.cache/spotify
    echo "done."
fi

$spotify "$@"
