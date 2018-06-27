#!/bin/sh

_Main() {
    [ ! -d "$1" ] || {
        echo "Creating log folder at $1"
        mkdir -p "$1" >/dev/null 2>&1
    }
}

_Main "$@"
