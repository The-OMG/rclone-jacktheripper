#!/usr/bin/env sh

_Main() {
    whereis $1 >/dev/null 2>&1 ||
        echo "$1 dependency not met/nPlease install $1" 1>&2 &&
        return 1
}

_Main "$@"
