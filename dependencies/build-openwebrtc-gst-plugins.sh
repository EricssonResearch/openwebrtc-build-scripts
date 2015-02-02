#!/bin/bash -e

BUILD_DIR=openwebrtc-gst-plugins
SCRIPT_DIR=../engine

GETTEXT_VERSION="0.18.2.1"
LIBXML2_VERSION="2.7.8"
OPENSSL_VERSION="1.0.2"
ORC_VERSION="0.4.22"
ICONV_VERSION="1.14"

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

local_clean_source() {
    echo "build-openwebrtc-gst-plugins.sh cleaning $BUILD_DIR"
    rm -fr $BUILD_DIR
}

install_sources() {
    git clone https://github.com/EricssonResearch/openwebrtc-gst-plugins.git $BUILD_DIR
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

    local configure_args="--host=${target_triple} --prefix=${installdir} --enable-static --enable-static-plugins --disable-shared"

    (
        cd $builddir

        if [[ $target_triple == "arm-apple-darwin10" ]]; then
            local configure_args="${configure_args} --enable-colorspace-converter"

            local optimize="-ggdb"
            [[ $do_release == yes ]] && {
                optimize="-O2"
            } || {
                configure_args="$configure_args --enable-debug"
            }

            $CC $CFLAGS -c -o ${builddir}/my_environ.o ${home}/my_environ.c
            $CC $CFLAGS -c -o ${builddir}/my_stat.o ${home}/my_stat.c

            export OBJC=$CC
            export OBJCLD=$OBJC

            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib ${builddir}/my_environ.o ${builddir}/my_stat.o -framework Foundation"
            export LIBS="-lintl -liconv -lz -lresolv"
            export CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
            export PLATFORM_CXXFLAGS="$PLATFORM_CFLAGS -std=c++11 -stdlib=libc++"
        elif [[ $target_triple == "i386-apple-darwin10" ]]; then
            local configure_args="${configure_args}"

            local optimize="-ggdb"
            [[ $do_release == yes ]] && {
                optimize="-O2"
            } || {
                configure_args="$configure_args --enable-debug"
            }
            export OBJC=$CC
            export OBJCLD=$OBJC

            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib -framework Foundation"
            export LIBS="-lintl -liconv -lz -lresolv"
            export PLATFORM_CXXFLAGS="$PLATFORM_CFLAGS -std=c++11 -stdlib=libc++"
        elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            local configure_args="${configure_args} --enable-android-plugins --enable-colorspace-converter"
            local extra_CFLAGS="-Wall"
            local optimize="-g -O0"
            [[ $do_release == yes ]] && {
                optimize="-O2 -DNDEBUG -g"
            } || {
                configure_args="$configure_args --enable-debug"
            }
            # Basic highlighting of warnings and errors for android builds.
            local highlight="| grep -E --color=auto \"$|.*error:.*|.*warning:.*\""

            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib -L${installdir}/../libiconv-${ICONV_VERSION}/lib -L${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/4.8/libs/armeabi-v7a"
            export LIBS="-lintl -liconv -lz"
            export PLATFORM_CXXFLAGS="-fno-rtti -fno-exceptions -I${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/4.8/libs/armeabi-v7a/include -I${ANDROID_NDK}/sources/cxx-stl/gnu-libstdc++/4.8/include"
        elif [[ $target_triple == "x86_64-unknown-linux" ]]; then
            local configure_args="${configure_args} --enable-linux-plugins"

            export LIBS="-lrt -lz -lm -lpthread -ldl -lresolv"
        elif [[ $target_triple == "x86_64-apple-darwin" ]] ; then
            local configure_args="${configure_args} --enable-osx-plugins"

            export LDFLAGS="-L${installdir}/../gettext-${GETTEXT_VERSION}/lib -framework Foundation"
            export LIBS="-liconv -lintl -lz -lresolv"
            export PLATFORM_CXXFLAGS="$PLATFORM_CFLAGS -std=c++11 -stdlib=libc++"
        fi

        # Common exports
        export CFLAGS="$CFLAGS $PLATFORM_CFLAGS"
        export GLIB_CFLAGS="-I${installdir}/../glib/include/glib-2.0 -I${installdir}/../glib/lib/glib-2.0/include"
        export GLIB_LIBS="-L${installdir}/../glib/lib -lglib-2.0 -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0"
        export GST_PLUGINS_BASE_CFLAGS="-I${installdir}/../gst-plugins-base/include/gstreamer-1.0"
        export GST_PLUGINS_BASE_LIBS="-L${installdir}/../gst-plugins-base/lib -lgstvideo-1.0"
        export
        GST_PLUGINS_BAD_CFLAGS="-I${installdir}/../gst-plugins-bad/include/gstreamer-1.0 -I${installdir}/../gst-plugins-bad/lib/gstreamer-1.0/include"
        export GIO_LIBS="-L${installdir}/../glib/lib -lgio-2.0"
        export ORC_CFLAGS="-I${installdir}/../orc-${ORC_VERSION}/include/orc-0.4"
        export ORC_LIBS="-L${installdir}/../orc-${ORC_VERSION}/lib -lorc-0.4"
        export GST_TOOLS_DIR="${installdir}/../gstreamer/bin"
        export GST_PREFIX="${installdir}/../gstreamer"
        export GST_LIBS="-L${installdir}/../gstreamer/lib -lgstreamer-1.0 "$GLIB_LIBS
        export GST_CFLAGS="-I${installdir}/../gstreamer/include/gstreamer-1.0 -I${installdir}/../gstreamer/lib/gstreamer-1.0/include "$GLIB_CFLAGS
        export GST_BASE_LIBS=$GST_LIBS" -lgstbase-1.0"
        export GST_CHECK_LIBS="$GST_LIBS -lgstcheck-1.0"
        export GST_CONTROLLER_LIBS="$GST_LIBS -lgstcontroller-1.0"
        export GST_GDP_LIBS="$GST_LIBS -lgstdataprotocol-1.0"
        export GST_PLUGINS_DIR="$GST_PREFIX/lib/gstreamer-1.0"
        export XML_CFLAGS="-I${installdir}/../libxml2-${LIBXML2_VERSION}/include/libxml2"
        export XML_LIBS="-L${installdir}/../libxml2-${LIBXML2_VERSION}/lib -lxml2"
        export OPENSSL_CFLAGS="-I${installdir}/../openssl-${OPENSSL_VERSION}/include"
        export OPENSSL_LIBS="-L${installdir}/../openssl-${OPENSSL_VERSION}/lib -lssl -lcrypto"
        export FFI_CFLAGS="-I${installdir}/../libffi/include"
        export FFI_LIBS="-L${installdir}/../libffi/lib -lffi"
        export USRSCTP_CFLAGS="-I${installdir}/../libusrsctp/include"
        export USRSCTP_LIBS="-L${installdir}/../libusrsctp/lib -lusrsctp"

        export GIO_CFLAGS=$GLIB_CFLAGS
        export GST_BASE_CFLAGS=$GST_CFLAGS
        export GST_CHECK_CFLAGS=$GST_CFLAGS
        export GST_CONTROLLER_CFLAGS=$GST_CFLAGS
        export GST_GDP_CFLAGS=$GST_CFLAGS

        export CFLAGS="$CFLAGS $GST_CFLAGS $GST_PLUGINS_BASE_CFLAGS $XML_CFLAGS $FFI_CFLAGS $OPENSSL_CFLAGS $USRSCTP_CFLAGS -DGST_PLUGIN_BUILD_STATIC"
        export LDFLAGS="$LDFLAGS $XML_LIBS"
        export CXXFLAGS="$CFLAGS $PLATFORM_CXXFLAGS"
        export OBJCFLAGS="$CFLAGS -fno-objc-arc"
        export LIBS="-lxml2 $GST_BASE_LIBS $GST_PLUGINS_BASE_LIBS $GIO_LIBS $ORC_LIBS $GST_LIBS $FFI_LIBS $OPENSSL_LIBS $USRSCTP_LIBS $LIBS"

        export CFLAGS="$CFLAGS ${extra_cflags} ${optimize}"

        local make_cmd="make 2>&1 ${highlight}"

        {
            pushd ${home}/$BUILD_DIR > /dev/null
            ./autogen.sh
            popd > /dev/null
        } &&
        {
            ${home}/$BUILD_DIR/configure ${configure_args} || exit 1
        } &&
        eval ${make_cmd} && make install

        )
}

. $SCRIPT_DIR/engine.sh
