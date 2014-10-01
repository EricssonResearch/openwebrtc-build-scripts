#!/bin/bash -e

GETTEXT_VERSION="0.18.2.1"
JSON_GLIB_VERSION="0.14.2"

BUILD_DIR=json-glib
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone git://git.gnome.org/json-glib $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard $JSON_GLIB_VERSION
    )
}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

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
        rm -fr * # clean the build to be sure

        export CFLAGS=$PLATFORM_CFLAGS
        if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
            $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c
            local extra_object_files="${builddir}/my_environ.o ${builddir}/my_stat.o"
            export CFLAGS="$CFLAGS -I${installdir}/../gettext-${GETTEXT_VERSION}/include"
            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib"
            export LIBS="-lintl"
        elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            export CFLAGS="$CFLAGS -I${installdir}/../gettext-${GETTEXT_VERSION}/include"
            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib"
        elif [[ $target_triple == "x86_64-apple-darwin" ]]; then
            export CFLAGS="$CFLAGS -I${installdir}/../gettext-${GETTEXT_VERSION}/include"
            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib"
            export LIBS="-lintl"
         fi

        export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
        export GLIB_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgio-2.0 -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0 ${extra_object_files}"

        export LIBS="$LIBS $GLIB_LIBS"
        export CPPFLAGS="$CFLAGS $GLIB_CFLAGS"

        cp -Rp ${home}/$BUILD_DIR/* . # due to bad support for out of source build

        ./autogen.sh \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --disable-shared \
            --disable-glibtest \
            --disable-introspection \
            && make && make install

        )
}

dependencies(){
    echo glib gettext libiconv
}

# run
. $SCRIPT_DIR/engine.sh
