#!/usr/bin/env bash

_dir=$(dirname $(realpath ${BASH_SOURCE[0]}))
_local=${_dir}/themes/hugo-pure
_remote=${_dir}/../hugo-pure

if [[ ! -f ${_local}/theme.toml ]]; then
    echo "${_local} is not theme repo"
    exit 1
fi

if [[ ! -f ${_remote}/theme.toml ]]; then
    echo "${_remote} is not theme repo"
    exit 1
fi

case $1 in
    pull)
        rsync -va -P --del --exclude=.git* --exclude=public --exclude=resources \
            ${_remote}/ ${_local}
        ;;
    push)
        rsync -va -P --del --exclude=.git* --exclude=public --exclude=resources \
            ${_local}/ ${_remote}
        ;;
    *)
        echo "Usage: $(basename $0) <pull|push>"
        exit 1
        ;;
esac
