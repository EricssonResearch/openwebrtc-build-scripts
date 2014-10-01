#!/bin/bash -e

READLINE_VERSION="6.3"
WEBKITGTK_DOWNLOAD_VERSION="2.4.3a"
WEBKITGTK_VERSION="2.4.3"

BUILD_DIR=webkitgtk-$WEBKITGTK_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://webkitgtk.org/releases/webkitgtk-$WEBKITGTK_DOWNLOAD_VERSION.tar.xz
    curl -o webkit_threading_platform_mac.patch https://bug-58737-attachments.webkit.org/attachment.cgi?id=211348
    curl https://android.googlesource.com/platform/external/chromium/+/d9f0c9b/android/execinfo.h?format=TEXT | base64 -D -o execinfo.h
    unxz -c webkitgtk-$WEBKITGTK_DOWNLOAD_VERSION.tar.xz | tar xv
    pushd webkitgtk-$WEBKITGTK_VERSION > /dev/null
    tail -22 ../webkit_threading_platform_mac.patch | patch -p1 || die "$0 - Could not apply patch."
    patch -p0 < ../webkit_disable_non_gtk_ios_features.patch || die "$0 - Could not apply patch."
    patch -p0 < ../webkit_have_langinfo_defined.patch || die "$0 - Could not apply patch."
    patch -p0 < ../webkit_math_extras_log2.patch || die "$0 - Could not apply patch."
    popd > /dev/null
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)
    (
    cd ${builddir}

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" || $target_triple == "x86_64-apple-darwin" ]]; then
        echo "No build needed for ${target_triple}."
        return 0
    fi

    export CFLAGS=$PLATFORM_CFLAGS" -I${installdir}/../icu/include"
    export CFLAGS+=" -I. -I${installdir}/../readline-$READLINE_VERSION/include"
    export CPPFLAGS=$CFLAGS" -DJSC_OBJC_API_ENABLED=0 -DENABLE_REMOTE_INSPECTOR=0"
    export CXXFLAGS=$CFLAGS
    export LDFLAGS="-L${installdir}/../icu/lib -licui18n -licuuc -licudata"
    export LDFLAGS+=" -L${installdir}/../readline-$READLINE_VERSION/lib -lhistory -lreadline"
    export AR_FLAGS="cru"
    export PKG_CONFIG_PATH="${installdir}/../glib/lib/pkgconfig"
    export PATH="${installdir}/../icu/bin:$PATH"

    export CAIRO_CFLAGS="x"
    export CAIRO_LIBS="x"
    export FREETYPE_CFLAGS="x"
    export FREETYPE_LIBS="x"
    export GTK_CFLAGS="x"
    export GTK_LIBS="x"
    export GTK2_CFLAGS="x"
    export GTK2_LIBS="x"
    export LIBSOUP_CFLAGS="x"
    export LIBSOUP_LIBS="x"
    export LIBXSLT_CFLAGS="x"
    export LIBXSLT_LIBS="x"
    export PANGO_CFLAGS="x"
    export PANGO_LIBS="x"
    export SQLITE3_CFLAGS="x"
    export SQLITE3_LIBS="x"
    export ac_cv_lib_jpeg_jpeg_destroy_decompress="yes"
    export ac_cv_header_png_h="yes"
    export ac_cv_lib_png_png_read_info="yes"
    export ac_cv_header_webp_decode_h="yes"
    touch jpeglib.h
    echo "typedef void* png_structp; typedef void* png_infop; typedef void* png_colorp;" > png.h
    echo "typedef void* png_create_read_struct;" >> png.h

    if [[ $target_triple == "arm-linux-androideabi" ]]; then
        local platform_configure_flags="--disable-jit"
        ANDROID_CXXSTL="$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.8"
        export CXXFLAGS+=" -std=c++11 -frtti -fexceptions -U__GNUC_PATCHLEVEL__ -D__GNUC_PATCHLEVEL__=1"
        export CXXFLAGS+=" -I$ANDROID_CXXSTL/include -I$ANDROID_CXXSTL/libs/armeabi-v7a/include"
        export CXXFLAGS+=" -DPTHREAD_KEYS_MAX=1024 -DHWCAP_VFP=64 -DHAVE_LANGINFO_H=0"
        export LDFLAGS+=" -lsupc++ -lstdc++ -L${builddir} -L$ANDROID_CXXSTL/libs/armeabi-v7a -lgnustl_static"
        ln -fs ${ANDROID_SYSROOT}/usr/lib/libc.so ${builddir}/libpthread.so
        mkdir -p asm
        touch asm/hwcap.h
        cp -f ${home}/execinfo.h .
    fi

    cp -R ${home}/$BUILD_DIR/DerivedSources .
    mkdir -p ${installdir}/lib
    ${home}/$BUILD_DIR/configure \
        --prefix=$PREFIX \
        --host=${target_triple} \
        ${platform_configure_flags} \
        --enable-static \
        --disable-shared \
        --disable-glibtest \
        --disable-x11-target \
        --disable-credential-storage \
        --disable-geolocation \
        --disable-video \
        --disable-web-audio \
    && make jsc
    # make fails on some platforms, so installation is done separately
    DESTDIR=${installdir} make install-libjavascriptcoregtk_3_0_laHEADERS \
    && cp .libs/libjavascriptcoregtk-3.0.a ${installdir}/lib
    )
}

dependencies() {
    echo readline glib icu
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
