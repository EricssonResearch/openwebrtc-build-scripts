#!/bin/bash -e

GNUTLS_VERSION="3_2_4"
GMP_VERSION="5.1.2"
NETTLE_VERSION="2.7.1"

BUILD_DIR=gnutls
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone https://gitlab.com/gnutls/gnutls.git $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard gnutls_${GNUTLS_VERSION}
    )
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
    cd ${builddir}

    export CFLAGS="$PLATFORM_CFLAGS"
    export GMP_CFLAGS="-I${installdir}/../gmp-${GMP_VERSION}/include"
    export GMP_LIBS="-L${installdir}/../gmp-${GMP_VERSION}/lib -lgmp"
    export NETTLE_CFLAGS="-I${installdir}/../nettle-${NETTLE_VERSION}/include"
    export NETTLE_LIBS="-L${installdir}/../nettle-${NETTLE_VERSION}/lib -lnettle"
    export HOGWEED_CFLAGS="-I${installdir}/../nettle-${NETTLE_VERSION}/include"
    export HOGWEED_LIBS="-L${installdir}/../nettle-${NETTLE_VERSION}/lib -lhogweed"

    if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
        local platform_configure_flags="-host arm"
        export AR="ar"
    elif [[ $target_triple == "i386-apple-darwin10" ]]; then
        local platform_configure_flags="--disable-hardware-acceleration"
        export AR="ar"
    elif [[ $target_triple == "x86_64-apple-darwin" ]]; then
        export AR="ar"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="-host arm"
        mkdir ${builddir}/dummy
        echo "void dummy(void) {}" > ${builddir}/dummy/dummy.c
        $CC $CFLAGS -c -o ${builddir}/dummy/dummy.o ${builddir}/dummy/dummy.c
        $AR -q ${builddir}/dummy/libgnu.a ${builddir}/dummy/dummy.o || exit 1
        rm -f ${builddir}/gl/.libs/libgnu.a
        export LDFLAGS="-L${builddir}/dummy -L${builddir}/gl/.libs -lgnu"
        export CFLAGS="$CFLAGS -std=c99 -DSIZE_MAX=0xffffffffU"
        export CPPFLAGS=$CFLAGS
    fi

    if [[ $target_triple != "x86_64-unknown-linux" ]]; then
        mkdir ${builddir}/error
        export CFLAGS="$CFLAGS -I${builddir}/error"
        export LDFLAGS="$LDFLAGS -L${builddir}/error -lmyerror"
        echo "void error(int s, int e, const char *format, ...);" > ${builddir}/error/error.h
        echo "void error(int s, int e, const char *format, ...) {}" > ${builddir}/error/error.c
        $CC $CFLAGS -c -o ${builddir}/error/error.o ${builddir}/error/error.c
        $AR -q ${builddir}/error/libmyerror.a ${builddir}/error/error.o || exit 1
    fi

    cp -Rp ${home}/$BUILD_DIR/* .

    make autoreconf
    libtoolize
    autoreconf
    automake --add-missing

    ./configure \
        ${platform_configure_flags} \
        --enable-static \
        --disable-shared \
        --disable-doc \
        --disable-tests \
        --disable-cxx \
        --disable-openssl-compatibility \
        --prefix=${installdir} || exit 1
    echo -e "all:\n\ninstall:\n" > po/Makefile
    make && make install
    )
}

dependencies(){
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
