#!/bin/bash -e

LIBSOUP_VERSION="2.44.2"
SQLITE_VERSION="3080500"
LIBXML2_VERSION="2.7.8"
GETTEXT_VERSION="0.18.2.1"

BUILD_DIR=libsoup
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    local home=$(pwd)

    git clone git://git.gnome.org/libsoup $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard $LIBSOUP_VERSION
    )
}

patch_sources() {
    local arch=$1
    local target_triple=$2

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
        rm -rf *

        export GNUTLS_CFLAGS="-I${installdir}/../gnutls/include"
        export GNUTLS_LIBS="-L${installdir}/../gnutls/lib -lgnutls"
        export SQLITE_CFLAGS="-I${installdir}/../sqlite-autoconf-${SQLITE_VERSION}/include"
        export SQLITE_LIBS="-L${installdir}/../sqlite-autoconf-${SQLITE_VERSION}/lib -lsqlite3"
        export XML_CFLAGS="-I${installdir}/../libxml2-${LIBXML2_VERSION}/include/libxml2"
        export XML_LIBS="-L${installdir}/../libxml2-${LIBXML2_VERSION}/lib -lxml2"

        export CFLAGS="$PLATFORM_CFLAGS $GNUTLS_CFLAGS"
        export PKG_CONFIG_PATH="${installdir}/../glib/lib/pkgconfig"

        if [[ ${target_triple} != "x86_64-unknown-linux" ]]; then
            export CPPFLAGS="-I${installdir}/../gettext-${GETTEXT_VERSION}/include"
            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib -lintl"
        fi

        if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
            local platform_configure_flags="--disable-introspection"
            LDFLAGS="$LDFLAGS ${builddir}/../glib/my_environ.o ${builddir}/../glib/my_stat.o"
        elif [[ ${target_triple} == "arm-linux-androideabi" ]]; then
            local platform_configure_flags="--disable-introspection"
        fi

        ${home}/$BUILD_DIR/autogen.sh \
            ${platform_configure_flags} \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --disable-shared \
            --disable-glibtest \
            --disable-tls-check \
            --disable-more-warnings \
            && make && make install

        )
}

dependencies() {
    echo glib sqlite libxml2 gnutls
}

# run
. $SCRIPT_DIR/engine.sh
