#!/bin/bash -e

GST_VERSION="fbd4cf9810a694c1928461f0b97d062b773bee60"
LIBICONV_VERSION="1.14"
LIBXML2_VERSION="2.7.8"
ORC_VERSION="0.4.22"
OPUS_VERSION="1.0.3"
OPENSSL_VERSION="1.0.2"

BUILD_DIR=gst-plugins-bad
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions(){
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    local home=$(pwd)

    git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-bad $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard $GST_VERSION
        git revert --no-edit 5f8a3fa0a3bf4712b06e5a799ebede6fd3ae81c4 || die "Failed to revert X-detection using pkg-config"
    )
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
    )
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
        export CFLAGS="$CFLAGS $PLATFORM_CFLAGS"
        export CPPFLAGS="$CFLAGS"
        export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"

	if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
            $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
            local extra_object_files="${builddir}/my_environ.o ${builddir}/my_stat.o"
	    local extra_configure_flags="--disable-orc --disable-opensles"
            export OBJC="$CC $CFLAGS"
	    export OBJCLD=$OBJC

        elif [[ ${target_triple} == "arm-linux-androideabi" ]]; then
            local extra_ldflags="-L${builddir}"
            #FIXME Allow ORC when ORC bug fixed
            local extra_configure_flags="--disable-orc --with-libiconv-prefix=${installdir}/../libiconv-${LIBICONV_VERSION}"
            ln -s ${ANDROID_SYSROOT}/usr/lib/libc.so ${builddir}/libpthread.so
            export ac_cv_lib_srtp_srtp_init="yes"
        elif [[ ${target_triple} == "x86_64-unknown-linux" ]]; then
            export ac_cv_lib_srtp_srtp_init="yes"
        fi

	export LDFLAGS="${extra_object_files} ${extra_ldflags}"
	export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
	export GLIB_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0"
	export GIO_CFLAGS=$GLIB_CFLAGS
	export GIO_LIBS="-L${installdir}/../glib/lib -lgio-2.0"
	export GST_CFLAGS="-I${installdir}/../gstreamer/include/gstreamer-1.0 -I${installdir}/../gstreamer/lib/gstreamer-1.0/include "$GLIB_CFLAGS
	export GST_LIBS="-L${installdir}/../gstreamer/lib -lgstreamer-1.0 "$GLIB_LIBS
	export GST_BASE_CFLAGS=$GST_CFLAGS
	export GST_BASE_LIBS=$GST_LIBS" -lgstbase-1.0"
	export GST_CHECK_CFLAGS=$GST_CFLAGS
	export GST_CHECK_LIBS=$GST_LIBS" -lgstcheck-1.0"
	export GST_CONTROLLER_CFLAGS=$GST_CFLAGS
	export GST_CONTROLLER_LIBS=$GST_LIBS" -lgstcontroller-1.0"
	export GST_GDP_CFLAGS=$GST_CFLAGS
	export GST_GDP_LIBS=$GST_LIBS" -lgstdataprotocol-1.0"
	export GST_PREFIX="${installdir}/../gstreamer"
	export GST_PLUGINS_DIR="${GST_PREFIX}/lib/gstreamer-1.0"
        export OPENH264_LIBS="-L${installdir}/../openh264/lib -lopenh264"
        export OPENH264_CFLAGS="-I${installdir}/../openh264/include"
	export OPUS_CFLAGS="-I${installdir}/../opus-${OPUS_VERSION}/include"
	export OPUS_LIBS="-L${installdir}/../opus-${OPUS_VERSION}/lib -lopus"
	export SRTP_CFLAGS="-I${installdir}/../libsrtp/include -I${installdir}/../openssl-$OPENSSL_VERSION/include"
	export SRTP_LIBS="-L${installdir}/../libsrtp/lib -lsrtp -L${installdir}/../openssl-$OPENSSL_VERSION/lib -lcrypto"
	export ORC_CFLAGS="-I${installdir}/../orc-${ORC_VERSION}/include/orc-0.4"
	export ORC_LIBS="-L${installdir}/../orc-${ORC_VERSION}/lib -lorc-0.4"
	export XML_CFLAGS="-I${installdir}/../libxml2-${LIBXML2_VERSION}/include/libxml2"
	export XML_LIBS="-L${installdir}/../libxml2-${LIBXML2_VERSION}/lib -lxml2"
	export CFLAGS="$CFLAGS $XML_CFLAGS $SRTP_CFLAGS $OPENH264_CFLAGS"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$LDFLAGS $XML_LIBS $SRTP_LIBS $OPENH264_LIBS"
	export OBJCFLAGS=$CFLAGS
	export GST_PLUGINS_BASE_CFLAGS="-I${installdir}/../gst-plugins-base/include/gstreamer-1.0"
	export GST_PLUGINS_BASE_LIBS="-L${installdir}/../gst-plugins-base/lib -lgstvideo-1.0"
	export GST_PLUGIN_LDFLAGS=$LDFLAGS
	export GST_LIBS=$GST_LIBS" "$GST_PLUGINS_BASE_LIBS
	export PKG_CONFIG_PATH="${installdir}/../gstreamer/lib/pkgconfig:${installdir}/../gst-plugins-base/lib/pkgconfig"

	{
	    pushd ${home}/$BUILD_DIR > /dev/null
	    ./autogen.sh --noconfigure
            popd > /dev/null
	} &&
	{
            # FIXME: Decklink seems to fail for android, lets disable it for now.
            # FIXME: The SRTP plugin produces warnings when compiling, so --disable-fatal-warnings is needed.
            ${home}/$BUILD_DIR/configure \
		--prefix=${installdir} \
		--host=${target_triple} \
                --disable-eglgles \
                --disable-asfmux \
                --disable-freeverb \
                --disable-decklink \
                --disable-mpegtsmux \
                --disable-mpegpsmux \
                --disable-yadif \
		--disable-fatal-warnings \
		--enable-static \
		--disable-shared \
		--enable-static-plugins \
		--disable-introspection \
		--enable-gobject-cast-checks=no ${extra_configure_flags} \
		|| exit 1
	    echo -e "all:\n\ninstall:\n" > docs/Makefile
	    echo -e "all:\n\ninstall:\n" > tests/Makefile
	} &&
	ERROR_CFLAGS="" make && make install
	)
}

dependencies(){
    echo libxml2 libsrtp glib gstreamer gst-plugins-base
}

. $SCRIPT_DIR/engine.sh
