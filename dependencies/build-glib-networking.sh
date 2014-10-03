#!/bin/bash -e

GLIB_NETWORKING_VERSION="2.36.1"
GETTEXT_VERSION="0.18.2.1"

BUILD_DIR=glib-networking
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    local home=$(pwd)

    git clone git://git.gnome.org/glib-networking $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard $GLIB_NETWORKING_VERSION

        # static modules
        git remote add gst-sdk git://anongit.freedesktop.org/gstreamer-sdk/glib-networking
        git fetch gst-sdk
        git cherry-pick 4b52a16d29bf042b6d2542d5e555777b10e597d8

        curl https://build.opensuse.org/source/GNOME:Factory/glib-networking/glib-networking-fix-no-cert-bundles.patch?rev=fce3ec5d5f11e105fa6a25a520a6c8df -o glib-networking-fix-no-cert-bundles.patch|| die "Failed to download glib-networking patch"
        git apply glib-networking-fix-no-cert-bundles.patch || die "Failed to apply glib-networking patch"
        git commit --no-verify -a -m "Patching tls/gnutls/gtlsbackend-gnutls.c" || die "Failed to commit patch tls/gnutls/gtlsbackend-gnutls.c"
        rm -f glib-networking-fix-no-cert-bundles.patch
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

        export CFLAGS="$PLATFORM_CFLAGS $GNUTLS_CFLAGS"
        export PKG_CONFIG_PATH="${installdir}/../glib/lib/pkgconfig"

        if [[ ${target_triple} != "x86_64-unknown-linux" ]]; then
            export CPPFLAGS="-I${installdir}/../gettext-${GETTEXT_VERSION}/include"
            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib -lintl"
        fi

        if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            LDFLAGS="$LDFLAGS ${builddir}/../glib/my_environ.o ${builddir}/../glib/my_stat.o"
        fi

        ${home}/$BUILD_DIR/autogen.sh \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --disable-shared \
            --enable-static-modules \
            --disable-glibtest \
            --without-ca-certificates \
            --disable-more-warnings \
            && make && make install

        )
}

dependencies(){
    echo glib gmp nettle gnutls
}

# run
. $SCRIPT_DIR/engine.sh
