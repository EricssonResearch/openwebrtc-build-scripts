#!/bin/bash -e

BUILD_DIR=libusrsctp
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    svn checkout http://sctp-refimpl.googlecode.com/svn/trunk/KERN/usrsctp@8932 $BUILD_DIR
}

patch_sources() {
    local target_triple=$2
    echo "Patch sources for ${target_triple}"

    if [[ $target_triple == "arm-linux-androideabi" ]]; then
        (
            cd $BUILD_DIR/usrsctplib
            cat Makefile.am | sed "s/sctp_os_userspace.h/sctp_os_userspace.h ifaddrs.c ifaddrs.h/" > Makefile.am.bak
            mv Makefile.am.bak Makefile.am
            curl -O https://raw.githubusercontent.com/nirbheek/cerbero/43af1b204c6b6dbac88fdd4252f706b3fc4586c8/recipes/libusrsctp/ifaddrs.c
            curl -O https://raw.githubusercontent.com/nirbheek/cerbero/43af1b204c6b6dbac88fdd4252f706b3fc4586c8/recipes/libusrsctp/ifaddrs.h
            git add Makefile.am
            git add ifaddrs.{c,h}
            git commit -a -m 'ifaddrs fix'
            )
    fi
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
    cd ${builddir}

    export CFLAGS=$PLATFORM_CFLAGS
    export CPPFLAGS=$CFLAGS
    export CXXFLAGS=$CFLAGS

    if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
        local platform_configure_flags="--host=arm"
        mkdir -p include
        local PLATFORM_IOS_HEADERS=`find -s "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs" -iname iPhoneSimulator[7\|8]*.sdk -maxdepth 1 | tail -1`
        cp -fR ${PLATFORM_IOS_HEADERS}/usr/include/net include
        cp -fR ${PLATFORM_IOS_HEADERS}/usr/include/netinet include
        export CFLAGS="$CFLAGS -I$builddir/include -D__APPLE_USE_RFC_2292 -U__APPLE__ -D__Userspace_os_Darwin"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="--host=$arch --disable-inet6"
        export CFLAGS="$CFLAGS -D__Userspace_os_Linux"
    fi
    export CFLAGS="$CFLAGS -std=c99"

    cp -Rp ${home}/$BUILD_DIR/* .
    echo > programs/Makefile.am
    libtoolize --force
    aclocal
    autoconf
    automake --foreign --add-missing --copy

    ./configure \
        ${platform_configure_flags} \
        --enable-static \
        --disable-shared \
        --with-pic \
        --prefix=${installdir} \
        && make && make install
    )
}

dependencies(){
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
