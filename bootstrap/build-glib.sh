#!/bin/bash -e

GLIB_VERSION=sdk-release-sdk-2013.6

BUILD_DIR=glib
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-glib.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get glib
    git clone git://anongit.freedesktop.org/gstreamer-sdk/glib

    popd > /dev/null
}

build() {
    local arch=$1
    local target_triple=$2

    mkdir -p $PREFIX/bin
    mkdir -p $PREFIX/lib

    (cd $BUILD_DIR && git checkout $target_triple)

    pushd $BUILD_DIR > /dev/null

    export PATH=$PREFIX/bin:$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin
    export DYLD_LIBRARY_PATH=$PREFIX/lib
    export LD_LIBRARY_PATH=$PREFIX/lib
    export JHBUILD_PREFIX=$PREFIX
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
    export PKG_CONFIG=$PREFIX/bin/pkg-config
    export PYTHON=`which python2.7`
    export PYTHONPATH=$PREFIX/lib/python2.7/site-packages

    export CFLAGS=$PLATFORM_CFLAGS
    export CPPFLAGS=$PLATFORM_CFLAGS

    # build glib
    pushd glib
    git checkout $GLIB_VERSION
    export CFLAGS="$CFLAGS -I$PREFIX/include"
    export LDFLAGS="-L$PREFIX/lib -lz"
    if [[ $target_triple =~ .*-darwin.* ]];then
        export LDFLAGS="$LDFLAGS -lintl"
    fi
    ./autogen.sh --prefix=$PREFIX --disable-carbon --disable-dtrace --disable-compile-warnings \
        && make && make install || die "$0 -- Could not build glib."
    popd > /dev/null

    popd > /dev/null
}


# drive
. $SCRIPT_DIR/engine.sh
