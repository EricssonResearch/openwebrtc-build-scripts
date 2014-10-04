#!/bin/bash -e

OPENH264_VERSION="v1.1"

BUILD_DIR=openh264
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 -- Internet connection is broken."
}

install_sources() {
    git clone https://github.com/cisco/openh264.git $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    git reset --hard $OPENH264_VERSION

    grep -v ^PREFIX=/usr/local Makefile > Makefile.new
    mv Makefile.new Makefile
    git add Makefile
    git commit --no-verify -m "Remove hard-coded installation PREFIX."

    popd > /dev/null
}

patch_sources() {
    echo
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
        cd $BUILD_DIR
        git checkout $target_triple && git clean -xdff || {
            echo "ERROR: Could not checkout ${target_triple} in ${home}"
            exit 1
        }
    )

    (
     cd ${builddir}

     export PREFIX=${installdir}
     if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
        export PLATFORM_MAKE_OPTIONS='OS=ios ARCH=armv7'
     elif [[ $target_triple == "i386-apple-darwin10" ]]; then
        export PLATFORM_MAKE_OPTIONS='OS=ios ARCH=i386'
     elif [[ ${target_triple} == "arm-linux-androideabi" ]]; then
        export PLATFORM_MAKE_OPTIONS='OS=android TARGET=android-10 NDKROOT=${ANDROID_NDK}'
     else
        export PLATFORM_MAKE_OPTIONS=''
     fi

     cp -Rp ${home}/$BUILD_DIR/* .
     make libraries ${PLATFORM_MAKE_OPTIONS} && make ${PLATFORM_MAKE_OPTIONS} install-static

     )

}

dependencies(){
    echo
}

# All setup, let's roll.
. $SCRIPT_DIR/engine.sh
