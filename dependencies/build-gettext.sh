#!/bin/bash -e

GETTEXT_VERSION="0.18.2.1"
LIBICONV_VERSION="1.14"
LIBXML2_VERSION="2.7.8"

BUILD_DIR=gettext-$GETTEXT_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions(){
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources(){
    curl -O http://ftp.gnu.org/pub/gnu/gettext/gettext-$GETTEXT_VERSION.tar.gz
    gunzip -c gettext-$GETTEXT_VERSION.tar.gz | tar xv
}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (
        cd $BUILD_DIR
        git checkout $target_triple || {
            echo "Could not checkout $target_triple in $(pwd)"
            exit 1
        }

        if [[ $target_triple == "arm-apple-darwin10" ]]; then
            setup_ios_toolchain $arch $target_triple || exit 1
            cp ${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/usr/include/crt_externs.h .
            git add crt_externs.h .
            git commit --no-verify -m "Added crt_externs needed for ios builds."
        elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            cp ${home}/config.{guess,sub} build-aux/
            git commit --no-verify -a -m "Newer config.{guess,sub}"
        fi
   ) || exit 1
}

build(){
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    # get the right branch
    (
        cd $BUILD_DIR
        git checkout ${target_triple} || {
            echo "Could not checkout $target_triple in $(pwd)"
            exit 1
        }
    )

    (
	cd ${builddir}

        local make_cmd="make && make install"

	if [[ ${target_triple} =~ (i386|arm)"-apple-darwin10" ]]; then
            extra_configure_flags="--with-libiconv-prefix=${PLATFORM_IOS_SDK}/usr"
            export ac_cv_func_stpncpy=yes
            export gl_cv_func_stpncpy=yes
            local cflags="-Dlocale_charset=my_locale_charset"
	elif [[ $target_triple == "arm-linux-androideabi" ]]; then
            export gl_cv_header_working_stdint_h=yes
            extra_configure_flags="--with-libiconv-prefix=${installdir}/../libiconv-${LIBICONV_VERSION}/lib"
            local make_cmd="make -C gettext-tools/intl install"
	fi

	local flags="$PLATFORM_CFLAGS ${cflags} -I${home}/$BUILD_DIR"

        export CFLAGS=${flags}
        export CXXFLAGS=${flags}
        export CPPFLAGS=${flags}

        ${home}/$BUILD_DIR/configure \
            --prefix=${installdir} \
            --host=${target_triple} \
            --enable-static \
            --disable-shared \
            --disable-c++ \
            --with-libxml2-prefix=${installdir}/../libxml2-${LIBXML2_VERSION}/lib \
            ${extra_configure_flags} \
            && eval ${make_cmd}
	)
}

dependencies(){
    echo
}

. $SCRIPT_DIR/engine.sh
