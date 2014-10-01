#!/bin/bash -e

GOBJECT_INTROSPECTION_VERSION=1_36_0

BUILD_DIR=gobject-introspection
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-gobject-introspection.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get gobject-introspection
    git clone git://git.gnome.org/gobject-introspection

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

    # build gobject-introspection
    pushd gobject-introspection
    git checkout --force GOBJECT_INTROSPECTION_$GOBJECT_INTROSPECTION_VERSION
    # patch to prevent the scanner from thinking that clang is msvc
    git cherry-pick -Xtheirs 6697c86548f809bd65d3a5f736ac060ced7ccc6c
    export CFLAGS="$CFLAGS -I/Applications/Xcode.app/Contents//Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7"
    export CPPFLAGS=$CFLAGS
    export CC="gcc"
    ln -s $PREFIX/include/libintl.h $PREFIX/include/glib-2.0/libintl.h
    ./autogen.sh --prefix=$PREFIX --disable-tests && make && make install || exit 1
    popd > /dev/null

    popd > /dev/null
}


# drive
. $SCRIPT_DIR/engine.sh
