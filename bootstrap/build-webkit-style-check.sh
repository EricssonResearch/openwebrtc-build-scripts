#!/bin/bash -e

WEBKIT_STYLE_CHECK_VERSION=173870

BUILD_DIR=webkit-style-check
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "Internet connection is broken."
}

local_clean_source() {
    echo "build-webit-style-check.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get webkit-style-check
    svn checkout -r $WEBKIT_STYLE_CHECK_VERSION http://svn.webkit.org/repository/webkit/trunk/Tools/Scripts/webkitpy
    svn export -r $WEBKIT_STYLE_CHECK_VERSION http://svn.webkit.org/repository/webkit/trunk/Tools/Scripts/check-webkit-style

    popd > /dev/null
}

build() {
    local arch=$1
    local target_triple=$2

    mkdir -p $PREFIX/bin
    mkdir -p $PREFIX/lib

    (cd $BUILD_DIR && git checkout $target_triple)

    pushd $BUILD_DIR > /dev/null

    export PYTHONPATH=$PREFIX/lib/python2.7/site-packages

    mkdir -p $PYTHONPATH
    cp -R webkitpy $PYTHONPATH/.
    cp check-webkit-style $PREFIX/bin
    cp ../openwebrtc-style-check $PREFIX/bin
    chmod a+x $PREFIX/bin/openwebrtc-style-check

    popd > /dev/null
}


# drive
. $SCRIPT_DIR/engine.sh
