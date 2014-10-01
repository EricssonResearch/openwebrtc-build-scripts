#!/bin/bash -e

GTK_OSX_DOCBOOK_VERSION=1.1

BUILD_DIR=gtk-osx-docbook
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-gtk-osx-docbook.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get gtk-osx-docbook
    curl -f -O http://heanet.dl.sourceforge.net/project/gtk-osx/GTK-OSX%20Build/gtk-osx-docbook-$GTK_OSX_DOCBOOK_VERSION.tar.gz
    gunzip -c gtk-osx-docbook-$GTK_OSX_DOCBOOK_VERSION.tar.gz | tar xv

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

    # build gtk-osx-docbook
    pushd gtk-osx-docbook-$GTK_OSX_DOCBOOK_VERSION
    ./configure --prefix=$PREFIX && make && make install || die "$0 -- Could not build gtk-osx-docbook."
    popd > /dev/null

    popd > /dev/null
}


# drive
. $SCRIPT_DIR/engine.sh
