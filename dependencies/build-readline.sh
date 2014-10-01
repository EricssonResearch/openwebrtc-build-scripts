#!/bin/bash -e

READLINE_VERSION="6.3"

BUILD_DIR=readline-$READLINE_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://ftp.gnu.org/pub/gnu/readline/readline-$READLINE_VERSION.tar.gz
    gunzip -c readline-$READLINE_VERSION.tar.gz | tar xv
}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
        cd $BUILD_DIR

        git checkout ${target_triple} 2>&1 > /dev/null || {
            echo "Could not checkout out ${target_triple} in $(pwd)"
            exit 1
        }
    )
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (cd $BUILD_DIR; git checkout $target_triple)

    pushd $builddir > /dev/null

    export CFLAGS=$PLATFORM_CFLAGS
    export CPPFLAGS=$CFLAGS
    export bash_cv_wcwidth_broken="no"

    ${home}/$BUILD_DIR/configure \
        --prefix=${installdir} \
        --host=${target_triple} \
        --enable-static \
        --disable-shared \
        && make && make install

    popd > /dev/null
}

dependencies() {
    echo
}

. $SCRIPT_DIR/engine.sh
