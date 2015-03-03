#!/bin/bash -e

OPENSSL_VERSION="1.0.2"

BUILD_DIR=libsrtp
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone https://github.com/cisco/libsrtp.git $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard d63d4f03c69dfd339834a1ff1511b53a23902b05 || die "Could not reset git to d63d4f"
    )
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)


    (
        cd $BUILD_DIR
        git checkout $target_triple || {
            echo "ERROR: Could not checkout ${target_triple} in ${home}"
            exit 1
        }
    )

    (
        cd ${builddir}
        rm -rf ${installdir}
        mkdir -p ${installdir}

        export CFLAGS="$PLATFORM_CFLAGS -DRAND_bytes=openssl_RAND_bytes -O3"
        export PKG_CONFIG_PATH="${installdir}/../openssl-$OPENSSL_VERSION/lib/pkgconfig/"

        if [[ $target_triple == "x86_64-unknown-linux" ]] ; then
            export CFLAGS+=" -ldl"
        fi

        ${home}/$BUILD_DIR/configure \
            --host=${target_triple} \
            --prefix=${installdir} \
            --enable-pic \
            --enable-openssl \
            && make && make install \
    )
}

dependencies(){
    echo
}

. $SCRIPT_DIR/engine.sh
