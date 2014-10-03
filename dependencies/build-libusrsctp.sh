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
        mkdir -p include/linux include/netinet6 include/sys lib
        cd include
        cp ${ANDROID_SYSROOT}/usr/include/errno.h .
        echo -e "#include <pthread.h>\n#include <arpa/inet.h>\n#include <netinet/in.h>\n" >> errno.h
        echo -e "typedef unsigned long long u_quad_t;\ntypedef uint16_t in_port_t;\n" >> errno.h
        touch linux/ipv6.h netinet6/ip6_var.h sys/sysctl.h sys/uio.h sys/unistd.h
        curl -o linux/if_addr.h http://code.metager.de/source/raw/android/4.3/bionic/libc/kernel/common/linux/if_addr.h
        curl -O https://raw.githubusercontent.com/kmackay/android-ifaddrs/7fcc2a871d9b79f27fcff94bd7f94df8022380ec/ifaddrs.h
        curl -O https://raw.githubusercontent.com/kmackay/android-ifaddrs/7fcc2a871d9b79f27fcff94bd7f94df8022380ec/ifaddrs.c
        $CC $CFLAGS -c -o ifaddrs.o ifaddrs.c
        $AR -q ../lib/libifaddrs.a ifaddrs.o || exit 1
        cd ..
        export CFLAGS="$CFLAGS -I$builddir/include -D__Userspace_os_Linux"
        export LDFLAGS="-L$builddir/lib -lifaddrs"
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
