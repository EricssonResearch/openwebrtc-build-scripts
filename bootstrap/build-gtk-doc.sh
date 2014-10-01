#!/bin/bash -e

GTK_DOC_VERSION=1.18

BUILD_DIR=gtk-doc
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-gtk-doc.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get gtk-doc
    curl -f -O http://ftp.gnome.org/pub/GNOME/sources/gtk-doc/$GTK_DOC_VERSION/gtk-doc-$GTK_DOC_VERSION.tar.bz2
    bunzip2 -c gtk-doc-$GTK_DOC_VERSION.tar.bz2 | tar xv

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

    # build gtk-doc
    pushd gtk-doc-$GTK_DOC_VERSION
    ./configure --prefix=$PREFIX --with-xml-catalog=$PREFIX/etc/xml/catalog && make && make install || exit 1
    popd > /dev/null

    popd > /dev/null

}


# drive
. $SCRIPT_DIR/engine.sh
