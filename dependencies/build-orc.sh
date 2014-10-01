#!/bin/bash -e

ORC_VERSION="0.4.22"

BUILD_DIR=orc-$ORC_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

local_clean_source() {
    echo "build-orc.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    git clone git://anongit.freedesktop.org/git/gstreamer/orc $BUILD_DIR
    pushd $BUILD_DIR >/dev/null
    git reset --hard orc-$ORC_VERSION
    popd >/dev/null
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

    (
        cd $builddir

        if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
            export NM=nm
            export CFLAGS="$CFLAGS $PLATFORM_CFLAGS"
        elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            export CFLAGS="$PLATFORM_CFLAGS -L${builddir}"
            ln -s ${ANDROID_SYSROOT}/usr/lib/libc.so ${builddir}/libpthread.so
        else
            export CFLAGS=$PLATFORM_CFLAGS
        fi

        NOCONFIGURE=1 ${home}/$BUILD_DIR/autogen.sh \
        && ${home}/$BUILD_DIR/configure \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --disable-shared \
            && make && make install

        )
}

dependencies(){
    echo
}

#drive this script with function calls.
. $SCRIPT_DIR/engine.sh
