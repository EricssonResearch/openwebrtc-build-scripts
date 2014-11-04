#!/bin/bash -e

GETTEXT_VERSION="0.18.2.1"
LIBFFI_VERSION="3.0.13"
LIBICONV_VERSION="1.14"

ZLIB_VERSION="1.2.8"

BUILD_DIR=glib
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions(){
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources(){
    local home=$(pwd)

    git clone git://anongit.freedesktop.org/gstreamer-sdk/glib $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard sdk-release-sdk-2013.6
    )
}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    echo "Patch sources for ${target_triple}"

    (
	cd $BUILD_DIR
        git clean -xdf
        git reset --hard HEAD
	git checkout $target_triple || {
	    echo "ERROR: Could not checkout ${target_triple} in $(pwd)"
	    exit 1
	}

 	if [[ $target_triple == "arm-linux-androideabi" ]]; then
 	    cp ${home}/config.{guess,sub} .
 	    git commit --no-verify -a -m "Patched glib sources for android and updated config.{guess,sub}"
 	fi
 	)

}
build(){
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
	cd $BUILD_DIR
        git clean -xdf
        git reset --hard HEAD
	git checkout $target_triple || {
	    echo "ERROR: Could not checkout ${target_triple} in ${home}"
	    exit 1
	}
	)


    (
	cd ${builddir}

	export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib"
	export LIBFFI_CFLAGS="-I${installdir}/../libffi/lib/libffi-${LIBFFI_VERSION}/include"
	export LIBFFI_LIBS="-L${installdir}/../libffi/lib -lffi"
	export CPPFLAGS="$PLATFORM_CFLAGS -I${installdir}/../gettext-${GETTEXT_VERSION}/include"
	export CFLAGS="$CFLAGS $PLATFORM_CFLAGS"
	export CXXFLAGS="$CFLAGS"
	if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
	    export LDFLAGS="$LDFLAGS -L${PLATFORM_IOS_SDK}/usr/lib -framework Foundation"
	    export ZLIB_CFLAGS="-I${installdir}/../zlib-${ZLIB_VERSION}/include"
	    export ZLIB_LIBS="-L${installdir}/../zlib-${ZLIB_VERSION}/lib -lz"
	    export LIBS="-lintl -liconv -lresolv"

	    $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
	    $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
	    export CPPFLAGS="$CPPFLAGS -I${PLATFORM_IOS_SDK}/usr/include"

	    local extra_configure_flags="--with-libiconv=native --disable-dtrace" # i386 builds detects dtrace but cannot use it.
	    # For configure since it can't test this
	    export glib_cv_stack_grows=no
	    export glib_cv_uscore=no
	    export ac_cv_func_posix_getgrgid_r=yes
	    export ac_cv_func_posix_getpwuid_r=yes
            export ac_cv_func_memmove=yes
            export ac_cv_func__NSGetEnviron=no
            export ac_cv_sizeof___int64=8

        if [[ $target_triple == "arm-apple-darwin10" ]]; then
            export LDFLAGS="$LDFLAGS ${builddir}/my_environ.o ${builddir}/my_stat.o"
            export CPPFLAGS="$CPPFLAGS -Denviron=my_environ -Dstat=my_stat"
        fi
	elif [[ $target_triple == "arm-linux-androideabi" ]]; then
	    export LDFLAGS="$LDFLAGS -L${installdir}/../libiconv-${LIBICONV_VERSION}/lib"
	    export CPPFLAGS="$CPPFLAGS -I${installdir}/../libiconv-${LIBICONV_VERSION}/include"
	    export GLIB_GENMARSHAL="${BUILD_DIR}/glib-genmarshal-wrapper.sh"
	    export LIBS="-lintl -liconv"
	    local extra_configure_flags="--with-libiconv=gnu --disable-gtk-doc --disable-maintainer-mode --disable-silent-rules"
            export glib_cv_stack_grows=no
            export glib_cv_uscore=no
            export ac_cv_func_posix_getpwuid_r=no
            export ac_cv_func_nonposix_getpwuid_r=no
            export ac_cv_func_posix_getgrgid_r=no
            export ac_cv_func_nonposix_getgrgid_r=no

        elif [[ $target_triple == "x86_64-apple-darwin" ]]; then
            export LDFLAGS="$LDFLAGS -framework Foundation"
            export LIBS="-lintl -liconv -lresolv"
	    local extra_configure_flags="--disable-carbon -disable-dtrace"
    elif [[ $target_triple == "x86_64-unknown-linux" ]]; then
        export ZLIB_CFLAGS="-I${installdir}/../zlib-${ZLIB_VERSION}/include"
        export ZLIB_LIBS="-L${installdir}/../zlib-${ZLIB_VERSION}/lib -lz"
        local extra_configure_flags="--disable-selinux"
	fi

	${home}/$BUILD_DIR/autogen.sh \
	    --prefix=${installdir} \
	    --host=${target_triple} \
	    --enable-static \
	    --disable-shared \
	    --enable-debug=no \
            --disable-compile-warnings \
            --disable-libelf \
            --disable-dependency-tracking \
            --disable-dtrace \
            --disable-modular-tests ${extra_configure_flags} \
	    && { \
            echo -e "all:\n\ninstall:\n" > docs/Makefile
            echo -e "all:\n\ninstall:\n" > glib/tests/Makefile
        } || exit 1

        pushd ${builddir}/gio
        make gioenumtypes.c
        make gioenumtypes.h
        cp gioenumtypes.* ${home}/$BUILD_DIR/gio
        cp gnetworking.h ${home}/$BUILD_DIR/gio
        popd

        make && make install
	)
}

dependencies(){
    echo libxml2 gettext libffi zlib libiconv
}

. $SCRIPT_DIR/engine.sh
