#!/bin/bash -e

GST_VERSION="1.4"
LIBFFI_VERSION="3.0.13"
LIBXML2_VERSION="2.7.8"

BUILD_DIR=gstreamer
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources(){
    git clone git://anongit.freedesktop.org/git/gstreamer/gstreamer $BUILD_DIR
    pushd $BUILD_DIR > /dev/null
    git reset --hard $GST_VERSION

    popd > /dev/null

}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
        cd $BUILD_DIR &&
        git checkout ${target_triple} 2>&1 > /dev/null || {
            echo "Could not checkout out ${target_triple} in $(pwd)"
            exit 1
        }
        )

}

build(){
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (cd $BUILD_DIR; git checkout $target_triple)

    ( # subshell to avoid poluting the env.
	cd ${builddir}

	export CFLAGS="$CFLAGS $PLATFORM_CFLAGS"
	export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
	export GLIB_ONLY_CFLAGS=$GLIB_CFLAGS
	export LIBFFI_CFLAGS="-I${installdir}/../libffi/lib/libffi-${LIBFFI_VERSION}/include"
	export LIBFFI_LIBS="-L${installdir}/../libffi/lib -lffi"
	export XML_CFLAGS="-I${installdir}/../libxml2-${LIBXML2_VERSION}/include/libxml2"
	export XML_LIBS="-L${installdir}/../libxml2-${LIBXML2_VERSION}/lib -lxml2"
	export GLIB_LIBS="-L${installdir}/../glib/${target}/lib -lglib-2.0 -lgio-2.0 -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0"
    export LDFLAGS="$PLATFORM_LDFLAGS"
	if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            $CC $CFLAGS $GLIB_CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
            $CC $CFLAGS $GLIB_CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
	    export GLIB_LIBS="$GLIB_LIBS ${builddir}/my_environ.o ${builddir}/my_stat.o"
	    export GLIB_ONLY_LIBS=$GLIB_LIBS
	elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            export GLIB_ONLY_LIBS=$GLIB_LIBS

            ln -s ${sysroot}/usr/lib/libc.so ${builddir}/libpthread.so
	fi

	{
	    pushd ${home}/$BUILD_DIR > /dev/null
	    ./autogen.sh --noconfigure
	    popd > /dev/null
	} &&
	{
	    ${home}/${BUILD_DIR}/configure \
		--prefix=${installdir} \
		--host=${target_triple} \
		--enable-static \
		--disable-shared \
		--enable-static-plugins \
		--disable-introspection \
		--disable-tests \
		--disable-failing-tests \
		--disable-examples \
		--disable-fatal-warnings \
		--enable-gobject-cast-checks=no \
		|| exit 1
	    echo -e "all:\n\ninstall:\n" > docs/Makefile
	} &&
	make && make install
	)
}

dependencies(){
    echo libxml2 glib libffi
}

. $SCRIPT_DIR/engine.sh
