#!/bin/bash -e

GST_VERSION="1.4"
LIBXML2_VERSION="2.7.8"
ORC_VERSION="0.4.22"

BUILD_DIR=gst-plugins-base
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions(){
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources(){
    git clone git://anongit.freedesktop.org/git/gstreamer/gst-plugins-base $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard $GST_VERSION

        # videoscale: Add NV21 support
        git cherry-pick 8cab1ab5fca0e0084141525f89a8d703ea8dc285
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
        export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"

	if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
            $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
	    export LDFLAGS="${builddir}/my_environ.o ${builddir}/my_stat.o"
	    local extra_configure_flags="--disable-orc"
	elif [[ $target_triple == arm-linux-androideabi ]]; then
            export LDFLAGS="-L${builddir}"
            ln -s ${ANDROID_SYSROOT}/usr/lib/libc.so ${builddir}/libpthread.so
            #FIXME Allow ORC when ORC bug fixed
            local extra_configure_flags="--disable-orc"
	fi

	export GLIB_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0"
        export GIO_CFLAGS=$GLIB_CFLAGS
        export GIO_LIBS="-L${installdir}/../glib/lib -lgio-2.0"
        export GST_CFLAGS="-I${installdir}/../gstreamer/include/gstreamer-1.0 "$GLIB_CFLAGS
        export GST_LIBS="-L${installdir}/../gstreamer/lib -lgstreamer-1.0 "$GLIB_LIBS
        export GST_BASE_CFLAGS=$GST_CFLAGS
        export GST_BASE_LIBS=$GST_LIBS" -lgstbase-1.0"
        export GST_CHECK_CFLAGS=$GST_CFLAGS
        export GST_CHECK_LIBS=$GST_LIBS" -lgstcheck-1.0"
        export GST_CONTROLLER_CFLAGS=$GST_CFLAGS
        export GST_CONTROLLER_LIBS=$GST_LIBS" -lgstcontroller-1.0"
        export GST_GDP_CFLAGS=$GST_CFLAGS
        export GST_GDP_LIBS=$GST_LIBS" -lgstdataprotocol-1.0"
        export GST_PREFIX="${installdir}/../gstreamer/"
        export GST_TOOLS_DIR="§${installdir}/../gstreamer/bin"
        export GST_PLUGINS_DIR="${GST_PREFIX}/lib/gstreamer-1.0"
        export XML_CFLAGS="-I${installdir}/../libxml2-${LIBXML2_VERSION}/include/libxml2"
        export XML_LIBS="-L${installdir}/../libxml2-${LIBXML2_VERSION}/lib -lxml2"
        export ORC_CFLAGS="-I${installdir}/../orc-${ORC_VERSION}/include/orc-0.4"
        export ORC_LIBS="-L${installdir}/../orc-${ORC_VERSION}/lib -lorc-0.4"
        export CFLAGS="$CFLAGS $XML_CFLAGS"
        export LDFLAGS="$LDFLAGS $XML_LIBS"

	{
	    pushd ${home}/$BUILD_DIR > /dev/null
	    ./autogen.sh --noconfigure
	    popd > /dev/null
	} &&
	{
	    ${home}/$BUILD_DIR/configure \
		--prefix=${installdir} \
		--host=${target_triple} \
		--enable-static \
		--disable-x \
		--disable-shared \
		--enable-static-plugins \
		--disable-introspection \
		--disable-ogg \
		--disable-vorbis \
		--disable-theora \
		--disable-fatal-warnings \
		--enable-gobject-cast-checks=no ${extra_configure_flags} \
		|| exit 1
            echo -e "all:\n\ninstall:\n" > docs/Makefile
	} &&
        make && make install
        )
}

dependencies(){
    echo glib gstreamer orc libxml2
}

. $SCRIPT_DIR/engine.sh
