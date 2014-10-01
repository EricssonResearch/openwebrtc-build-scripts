#!/bin/bash -e

LIBTOOL_VERSION=2.4.2

BUILD_DIR=libtool
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-libtool.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get libtool
    curl -f -O http://ftp.gnu.org/gnu/libtool/libtool-$LIBTOOL_VERSION.tar.gz
    gunzip -c libtool-$LIBTOOL_VERSION.tar.gz | tar xv
    curl -f -o libtool_android.patch http://lists.gnu.org/archive/html/libtool-patches/2013-06/binqC7aisJ5tt.bin

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

    # build libtool
    pushd libtool-$LIBTOOL_VERSION
    pushd libltdl > /dev/null
    patch -p1 < ../../libtool_android.patch || die "$0 -- Could not patch libtool."
    popd > /dev/null
    ./configure --prefix=$PREFIX && make && make install || die "$0 -- Could not build libtool."
    popd > /dev/null

    popd > /dev/null
}


# drive
. $SCRIPT_DIR/engine.sh
