#!/bin/bash -e

SQLITE_VERSION="3080500"

BUILD_DIR=sqlite-autoconf-${SQLITE_VERSION}
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://www.sqlite.org/2014/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
    gunzip -c sqlite-autoconf-${SQLITE_VERSION}.tar.gz | tar xv
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
    cd ${builddir}

    export CFLAGS="$PLATFORM_CFLAGS -fno-common -fvisibility=protected"
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS=$CFLAGS

    cp -Rp ${home}/$BUILD_DIR/* .

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
        local platform_configure_flags="-host $target_triple"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="-host $target_triple"
        cp -f ${home}/config.{guess,sub} .
    fi

    ./configure \
        ${platform_configure_flags} \
        --enable-static \
        --disable-shared \
        --with-pic \
        --prefix=${installdir} \
        && make && make install
    )
}

dependencies() {
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
