#!/usr/bin/env bash

_sdir=$(dirname $(realpath ${BASH_SOURCE[0]}))
_theme=themes/hugo-pure

cd ${_sdir}

if [[ ! -d ${_theme} ]]; then
    mkdir -p themes
    curl -SLO https://github.com/undus5/hugo-pure/archive/refs/heads/main.zip
    unzip main.zip
    mv hugo-pure-main ${_theme}
    rm main.zip
fi

hugo --minify $@
