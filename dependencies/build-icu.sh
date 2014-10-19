#!/bin/bash -e

ICU_VERSION=53_1

BUILD_DIR=icu
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -LO http://download.icu-project.org/files/icu4c/${ICU_VERSION/_/.}/icu4c-$ICU_VERSION-src.tgz
    tar xzf icu4c-$ICU_VERSION-src.tgz
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)
    (
    cd ${builddir}

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
        echo "No build needed for ${target_triple}."
        return 0
    fi

    cp -Rp ${home}/$BUILD_DIR/* .
    cd source

    export CFLAGS=$PLATFORM_CFLAGS
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS=$CFLAGS
    export LDFLAGS=$PLATFORM_LDFLAGS

    if [[ $(uname) == "Darwin" ]]; then
        local host_platform="osx"
        local host_triple="x86_64-apple-darwin"
    elif [[ $(uname) == "Linux" ]]; then
        local host_platform="linux"
        local host_triple="x86_64-unknown-linux"
    fi

    if [[ ${target_triple} != ${host_triple} ]]; then
        (
        cd ${home} && ./build-icu.sh -r ${host_platform}
        )
        local cross_build="${builddir}/../../${host_triple}/icu/source"
    fi

    if [[ $target_triple == "arm-linux-androideabi" ]]; then
        ANDROID_CXXSTL="$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.8"
        export CXXFLAGS+=" -frtti -fexceptions -D__STDC_INT64__ -I$ANDROID_CXXSTL/include -I$ANDROID_CXXSTL/libs/armeabi-v7a/include"
        export LDFLAGS+=" -lsupc++ -lstdc++ -L${builddir} -L$ANDROID_CXXSTL/libs/armeabi-v7a -lgnustl_static"
        echo -e "all:\n\ninstall:\n" > tools/Makefile.in
    fi

    ./configure \
        --prefix=${installdir} \
        --host=${target_triple} \
        --with-cross-build=${cross_build} \
        --enable-static \
        --disable-dyload \
        --disable-shared \
        --disable-strict \
        --disable-extras \
        --disable-icuio \
        --disable-layout \
        --disable-tests \
        --disable-samples \
    && make && make install
    )
}

dependencies() {
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
