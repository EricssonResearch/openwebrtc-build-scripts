#!/bin/bash -e

GMP_VERSION="5.1.2"

BUILD_DIR=gmp-${GMP_VERSION}
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://ftp.sunet.se/pub/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
    bunzip2 -c gmp-${GMP_VERSION}.tar.bz2 | tar xv
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
    cd ${builddir}

    export CFLAGS="$PLATFORM_CFLAGS -fno-common"
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS=$CFLAGS

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
        local platform_configure_flags="-host $arch --disable-assembly"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="-host $arch"
        export CFLAGS="$CFLAGS -fvisibility=protected"
    fi

    cp -Rp ${home}/$BUILD_DIR/* .

    ./configure \
        ${platform_configure_flags} \
        --enable-static \
        --disable-shared \
        --with-pic \
        --prefix=${installdir} \
        && make && make install
    )
}

dependencies(){
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
