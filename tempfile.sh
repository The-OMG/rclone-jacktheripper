#!/bin/sh

_Main() {
    mktemp -q "$SCRATCH"/$1.XXXX || {
        echo "$1: Can't create temp file, exiting..." &&
            exit 1
    }
}
_Main "$@"
