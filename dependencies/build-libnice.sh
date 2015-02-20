#!/bin/bash -e

LIBXML2_VERSION="2.7.8"
LIBICONV_VERSION="1.14"
LIBNICE_VERSION="0.1.10"

BUILD_DIR=libnice
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone git://anongit.freedesktop.org/libnice/libnice $BUILD_DIR
    pushd $BUILD_DIR > /dev/null
    git reset --hard $LIBNICE_VERSION

    # REMOVEME: The following patch enables synchronous DNS resolution
    # This should instead be implemented in the libnice user code using GResolver
    git am ../libnice_enable_dns.patch
    git am ../libnice_sink_wait_candidates.patch

    popd > /dev/null
}

patch_sources() {
    local arch=$1
    local target_triple=$2

    (
        cd $BUILD_DIR
        git checkout $target_triple || {
            echo "ERROR: Could not checkout ${target_triple} in $(pwd)"
            exit 1
        }

        if [[ $target_triple == "arm-apple-darwin10" ]]; then
            setup_ios_toolchain $arch $target_triple || exit 1
            # Copy missing header file
            mkdir -p net
            cp ${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/usr/include/net/if_arp.h net
            git add net/if_arp.h
            git commit --no-verify -a -m "Added missing header file."
        fi
    ) || exit 1
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

	export CFLAGS="$CFLAGS $PLATFORM_CFLAGS -I${installdir}/../libxml2-${LIBXML2_VERSION}/include/libxml2"
	export LIBS="-L${installdir}/../libxml2-${LIBXML2_VERSION}/lib -lxml2"
        export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include -DG_DISABLE_CAST_CHECKS"
        export GST_CFLAGS="-I${installdir}/../gstreamer/include/gstreamer-1.0 -I${installdir}/../gstreamer/lib/gstreamer-1.0/include "$GLIB_CFLAGS
        export GLIB_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgio-2.0 -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0"
        if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            local platform_configure_flags="--disable-introspection"
            $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
            $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
            export GLIB_LIBS="$GLIB_LIBS ${builddir}/my_environ.o ${builddir}/my_stat.o"
        elif [[ ${target_triple} == "arm-linux-androideabi" ]]; then
            local platform_configure_flags="--disable-introspection"
            export CFLAGS="$CFLAGS -I${installdir}/../libiconv-${LIBICONV_VERSION}/include"
        else
            local platform_configure_flags="--enable-gtk-doc"
            export XML_CATALOG_FILES=~/.openwebrtc/etc/xml/catalog
        fi
        export GST_LIBS="-L${installdir}/../gstreamer/lib -lgstreamer-1.0 -lgstbase-1.0 "$GLIB_LIBS
        {
            pushd ${home}/$BUILD_DIR > /dev/null
            git clean -xdff
            ./autogen.sh --no-configure
            popd > /dev/null
        } &&

        ${home}/$BUILD_DIR/configure \
            ${platform_configure_flags} \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --enable-static-plugins \
            --disable-shared \
            --with-gstreamer \
            --disable-compile-warnings \
            && make && make install
        )
}

dependencies(){
    echo glib libxml2 gstreamer libiconv
}

# All setup, let's roll.

. $SCRIPT_DIR/engine.sh
