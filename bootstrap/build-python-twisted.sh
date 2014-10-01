#!/bin/bash -e

PYTHON_TWISTED_VERSION=12.2.0

BUILD_DIR=python-twisted
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-python-twisted.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    #get python twisted
    curl -f -O https://twistedmatrix.com/Releases/Twisted/${PYTHON_TWISTED_VERSION%"."*}/Twisted-$PYTHON_TWISTED_VERSION.tar.bz2
    tar xvjpf Twisted-$PYTHON_TWISTED_VERSION.tar.bz2

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

    #build twisted
    pushd Twisted-$PYTHON_TWISTED_VERSION > /dev/null
    python setup.py install --prefix=$PREFIX --install-scripts=$PREFIX/bin
    popd > /dev/null

    popd > /dev/null
}


# drive
. $SCRIPT_DIR/engine.sh
