#!/bin/bash -e

GIREPO_VERSION="1_36_0"
LIBFFI_VERSION="3.0.13"

BUILD_DIR=gobject-introspection
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone https://git.gnome.org/browse/gobject-introspection $BUILD_DIR
    pushd $BUILD_DIR > /dev/null
    git reset --hard GOBJECT_INTROSPECTION_$GIREPO_VERSION
    popd > /dev/null
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)
    (
    cd ${builddir}

    export CFLAGS=$PLATFORM_CFLAGS
    export CPPFLAGS=$CFLAGS
    export LDFLAGS=$PLATFORM_LDFLAGS

    export FFI_CFLAGS="-I${installdir}/../libffi/lib/libffi-${LIBFFI_VERSION}/include"
    export FFI_LIBS="-L${installdir}/../libffi/lib -lffi"
    export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
    export GLIB_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgobject-2.0 -lgmodule-2.0 -lgio-2.0"
    export GOBJECT_CFLAGS=$GLIB_CFLAGS
    export GOBJECT_LIBS=$GLIB_LIBS
    export GMODULE_CFLAGS=$GLIB_CFLAGS
    export GMODULE_LIBS=$GLIB_LIBS
    export GIO_CFLAGS=$GLIB_CFLAGS
    export GIO_LIBS=$GLIB_LIBS
    export SCANNER_CFLAGS=$GLIB_CFLAGS
    export SCANNER_LIBS=$GLIB_LIBS
    export GIREPO_CFLAGS=$GLIB_CFLAGS
    export GIREPO_LIBS=$GLIB_LIBS
    export PKG_CONFIG_PATH=""

    if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
        $CC $CFLAGS $GLIB_CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
        $CC $CFLAGS $GLIB_CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
        export LDFLAGS+="$GLIB_LIBS ${builddir}/my_environ.o ${builddir}/my_stat.o"
    elif [[ $target_triple == "arm-linux-androideabi" ]]; then
        export LDFLAGS+=$GLIB_LIBS
    fi

    cp -Rp ${home}/$BUILD_DIR/* .
    echo > Makefile-gir.am
    echo > Makefile-giscanner.am
    echo > Makefile-tools.am
    ln -s `which g-ir-scanner` g-ir-scanner
    cp $HOME/.openwebrtc/lib/gobject-introspection/giscanner/_giscanner.so .

    ./autogen.sh \
        --prefix=${installdir} \
        --host=${triple} \
        --enable-static \
        --disable-shared \
        --disable-tests \
    && make && make install \
    && cp -f girepository/gitypelib-internal.h $installdir/include/gobject-introspection-1.0 \
    && cp -f girepository/girmodule.h $installdir/include/gobject-introspection-1.0 \
    && cp -f girepository/girparser.h $installdir/include/gobject-introspection-1.0 \
    && cp -f .libs/libgirepository-internals.a $installdir/lib

    mkdir -p  ${installdir}/include/gobject-introspection-1.0/gir
    pushd $HOME/.openwebrtc/share/gir-1.0 > /dev/null
    for filename in G*-2.0.gir; do
        xxd -i ${filename} > ${installdir}/include/gobject-introspection-1.0/gir/${filename}.h
        shasum -a 1 -b < ${filename} | head -c 40 > ${filename}.sha1
        xxd -i ${filename}.sha1 >> ${installdir}/include/gobject-introspection-1.0/gir/${filename}.h
        rm ${filename}.sha1
    done
    popd > /dev/null
    )
}

dependencies() {
    echo ffi glib
}

# drive the script by function calls.
. $SCRIPT_DIR/engine.sh
