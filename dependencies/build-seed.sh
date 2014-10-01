#!/bin/bash -e

LIBFFI_VERSION="3.0.13"
WEBKITGTK_VERSION="2.4.3"

BUILD_DIR=seed
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone https://github.com/GNOME/seed.git $BUILD_DIR
    pushd $BUILD_DIR > /dev/null
    git reset --hard cf772e792fd64f70ee2c714e0b5eaf527ce35467
    popd > /dev/null
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)
    (
    cd ${builddir}

    export CFLAGS=$PLATFORM_CFLAGS" -I${installdir}/../icu/include"
    export CPPFLAGS=$CFLAGS
    export LDFLAGS=$PLATFORM_LDFLAGS

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" || $target_triple == "x86_64-apple-darwin" ]]; then
        export WEBKIT_CFLAGS=" "
        export WEBKIT_LIBS="-framework JavaScriptCore"
    else
        export WEBKIT_CFLAGS="-I${installdir}/../webkitgtk-$WEBKITGTK_VERSION/include/webkitgtk-3.0"
        export WEBKIT_LIBS="-L${installdir}/../webkitgtk-$WEBKITGTK_VERSION/lib -ljavascriptcoregtk-3.0 -L${installdir}/../icu/lib -licui18n -licuuc -licudata"
    fi

    export GOBJECT_INTROSPECTION_CFLAGS="-I${installdir}/../gobject-introspection/include/gobject-introspection-1.0 -I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
    export GOBJECT_INTROSPECTION_LIBS="-L${installdir}/../gobject-introspection/lib -lgirepository-1.0 -L${installdir}/../glib/lib -lglib-2.0 -lgobject-2.0 -lgmodule-2.0 -lgio-2.0 -lgthread-2.0"
    export GIO_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
    export GIO_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgobject-2.0 -lgmodule-2.0 -lgio-2.0 -lgthread-2.0"
    export GMODULE_CFLAGS=$GIO_CFLAGS
    export GMODULE_LIBS=$GIO_LIBS
    export GTHREAD_CFLAGS=$GIO_CFLAGS
    export GTHREAD_LIBS=$GIO_LIBS
    export FFI_CFLAGS="-I${installdir}/../libffi/lib/libffi-${LIBFFI_VERSION}/include"
    export FFI_LIBS="-L${installdir}/../libffi/lib -lffi"
    export GNOME_JS_CFLAGS="-I."
    export GNOME_JS_LIBS="-L."

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
        $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
        $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
        export LDFLAGS+=" ${builddir}/my_environ.o ${builddir}/my_stat.o"
        export WEBKIT_LIBS+=" -lc++"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        ANDROID_CXXSTL="$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.8"
        export WEBKIT_LIBS+=" -lsupc++ -lstdc++ -L${builddir} -L$ANDROID_CXXSTL/libs/armeabi-v7a -lgnustl_static"
    elif [[ $target_triple == "x86_64-apple-darwin" ]]; then
        export WEBKIT_LIBS+=" -lc++"
    elif [[ $target_triple == "x86_64-unknown-linux" ]]; then
        export WEBKIT_LIBS+=" -lsupc++ -lstdc++"
    fi

    ${home}/$BUILD_DIR/autogen.sh \
        --prefix=${installdir} \
        --host=${target_triple} \
        --enable-static \
        --disable-shared \
        --with-pic \
        --disable-canvas-module \
        --disable-readline-module \
        --disable-multiprocessing-module \
        --disable-sqlite-module \
        --disable-xorg-module \
        --disable-example-module \
        --disable-dbus-module \
        --disable-os-module \
        --disable-ffi-module \
        --disable-libxml-module \
        --disable-dynamicobject-module \
        --disable-gtkbuilder-module \
        --disable-cairo-module \
        --disable-gettext-module \
        --disable-mpfr-module \
        && echo -e "all:\n\ninstall:\n" > doc/Makefile \
        && make && make install
    )
}

dependencies() {
    echo ffi glib girepository javascriptcoregtk
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
