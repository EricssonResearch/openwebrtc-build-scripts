#!/bin/bash -e

ZLIB_VERSION="1.2.8"

BUILD_DIR=zlib-$ZLIB_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    # no fast build, get source.
    curl --connect-timeout 5 -f -O http://zlib.net/zlib-$ZLIB_VERSION.tar.gz
    tar xvzf zlib-$ZLIB_VERSION.tar.gz
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
	cd ${builddir}

	if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
	    cp -R ${home}/$BUILD_DIR/* .
        archs="-arch ${arch}"
    elif [[ ${target_triple} == "x86_64-unknown-linux" ]]; then
        cp -R ${home}/$BUILD_DIR/* .
        archs=""
	else
	    echo "No build needed for ${target_triple}."
	    return 0
	fi
	export CFLAGS="$PLATFORM_CFLAGS"
	${home}/$BUILD_DIR/configure \
            --static \
            --archs="${archs}" \
            --prefix=${installdir} \
	    && make && make install \
	    )
}

dependencies(){
    echo
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
