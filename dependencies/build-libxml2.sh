#!/bin/bash -e

LIBXML2_VERSION="2.7.8"

BUILD_DIR=libxml2-$LIBXML2_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    # no fast build, get source.
    curl -O ftp://xmlsoft.org/libxml2/libxml2-sources-$LIBXML2_VERSION.tar.gz
    gunzip -c libxml2-sources-$LIBXML2_VERSION.tar.gz | tar xv

}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    echo "Patch sources for ${target_triple}"

    (
        cd $BUILD_DIR
        git checkout $target_triple || {
            echo "ERROR: Could not checkout ${target_triple} in $(pwd)"
            exit 1
        }

        if [[ $target_triple == "arm-linux-androideabi" ]]; then

            curl -O https://raw.githubusercontent.com/white-gecko/TokyoCabinet/1047194c79cbdd31d6026e7afe24b768e4991798/glob.h
            curl -O https://raw.githubusercontent.com/white-gecko/TokyoCabinet/1047194c79cbdd31d6026e7afe24b768e4991798/glob.c
            git add glob.h glob.c

            cp ${home}/config.{guess,sub} .

            git commit --no-verify -a -m "Added glob-files and updated config.{guess,sub}"

        fi
    )

}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
        cd $BUILD_DIR
        git checkout $target_triple || {
            echo "ERROR: Could not checkout ${target_triple} in ${home}"
            exit 1
        }
    )

    (
        cd ${builddir}

        if [[ $target_triple == "arm-linux-androideabi" ]]; then

        # Build glob.c and make sure it is linked with the final lib.
            $CC $PLATFORM_CFLAGS -c -o ${builddir}/glob.o ${home}/$BUILD_DIR/glob.c -I${home}/$BUILD_DIR
            ldflags="${builddir}/glob.o"
        fi

        export CFLAGS="${PLATFORM_CFLAGS} ${CFLAGS}"
        export LDFLAGS="$LDFLAGS ${ldflags}"
        ${home}/libxml2-$LIBXML2_VERSION/configure \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --disable-shared \
            --with-threads=posix \
            --with-iconv=no \
            --without-python \
            ${extra_configure_flags} && \
        make && make install
    )
}

dependencies(){
    echo
}

# All setup, let's go.
. $SCRIPT_DIR/engine.sh
