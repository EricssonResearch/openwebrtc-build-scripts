#!/bin/bash -e

OPUS_VERSION="1.0.3"

BUILD_DIR=opus-$OPUS_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://downloads.xiph.org/releases/opus/opus-$OPUS_VERSION.tar.gz
    gunzip -c opus-$OPUS_VERSION.tar.gz | tar xv
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
    cd ${builddir}

    export CFLAGS="$PLATFORM_CFLAGS"

    if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
        local platform_configure_flags="-host arm"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="-host arm"
    fi

    ${home}/$BUILD_DIR/configure \
        $platform_configure_flags \
        --prefix=${installdir} \
        --enable-static \
        --disable-shared \
        && make && make install
    )
}

dependencies(){
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
