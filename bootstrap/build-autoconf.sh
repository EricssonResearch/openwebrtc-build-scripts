#!/bin/bash -e

AUTOCONF_VERSION=2.68

BUILD_DIR=autoconf
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-autoconf.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get autoconf
    curl -f -O http://ftp.gnu.org/gnu/autoconf/autoconf-$AUTOCONF_VERSION.tar.bz2
    bunzip2 -c autoconf-$AUTOCONF_VERSION.tar.bz2 | tar xv

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

    # build autoconf
    pushd autoconf-$AUTOCONF_VERSION
    ./configure --prefix=$PREFIX && make && make install || die "$0 -- Could not build autoconf."
    popd > /dev/null

    popd > /dev/null

    # libiconv on android requires different names for autoconf and autoheader. soft links
    ln -sf $PREFIX/bin/autoconf $PREFIX/bin/autoconf-2.68
    ln -sf $PREFIX/bin/autoheader $PREFIX/bin/autoheader-2.68
}


# drive
. $SCRIPT_DIR/engine.sh
