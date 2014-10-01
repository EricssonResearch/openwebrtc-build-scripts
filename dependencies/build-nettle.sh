#!/bin/bash -e

NETTLE_VERSION="2.7.1"
GMP_VERSION="5.1.2"

BUILD_DIR=nettle-${NETTLE_VERSION}
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://www.lysator.liu.se/~nisse/archive/nettle-${NETTLE_VERSION}.tar.gz
    gunzip -c nettle-${NETTLE_VERSION}.tar.gz | tar xv
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
    cd ${builddir}

    export CFLAGS="$PLATFORM_CFLAGS -I${installdir}/../gmp-${GMP_VERSION}/include"
    export LDFLAGS="-L${installdir}/../gmp-${GMP_VERSION}/lib -lgmp"

    if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
        local platform_configure_flags="-host arm"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="-host arm"
    fi

    cp -Rp ${home}/$BUILD_DIR/* .

    ./configure \
        ${platform_configure_flags} \
        --enable-static \
        --disable-shared \
        --prefix=${installdir} \
        && echo -e "all:\n\ninstall:\n" > testsuite/Makefile \
        && make && make install
    )
}

dependencies(){
    echo gmp
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
