#!/bin/bash -e

OPENSSL_VERSION="1.0.2"

BUILD_DIR=openssl-$OPENSSL_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
    gunzip -c openssl-$OPENSSL_VERSION.tar.gz | tar xv
}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    cd $BUILD_DIR || exit

    git checkout ${target_triple} 2>&1 > /dev/null || {
        echo "Could not checkout out ${target_triple} in $(pwd)"
        exit 1
    }
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)


    (
        cd $BUILD_DIR && git checkout $target_triple && cd $builddir || exit

        cp -rf ${home}/$BUILD_DIR/* . || exit

        if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            local platform="BSD-generic32"
        elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            local platform="android-armv7"
        elif [[ $target_triple == "x86_64-apple-darwin" ]]; then
            local platform="darwin64-x86_64-cc"
        elif [[ $target_triple == "x86_64-unknown-linux" ]] ; then
            local platform="linux-x86_64"
            export CC="gcc"
        fi

        export CC="$CC $PLATFORM_CFLAGS  -DRAND_bytes=openssl_RAND_bytes"
        ./Configure \
            --prefix=${installdir} \
            $platform \
            no-shared \
            no-dso \
            && make && make install_sw
        )
}

dependencies(){
    echo
}

. $SCRIPT_DIR/engine.sh
