#!/bin/bash -e

LIBICONV_VERSION="1.14"

BUILD_DIR=libiconv-$LIBICONV_VERSION
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    curl -O http://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz
    gunzip -c libiconv-$LIBICONV_VERSION.tar.gz | tar xv
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

        if [[ $target_triple == "arm-linux-androideabi" ]]; then
            cp ${home}/config.{guess,sub} .
            cp ${home}/config.{guess,sub} build-aux/
            cp ${home}/config.{guess,sub} libcharset/build-aux/
            git commit --no-verify -a -m "Sedded some files for android build"
        fi
    )
}

build() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    (cd $BUILD_DIR; git checkout $target_triple)

    pushd $builddir /dev/null

    if [[ $target_triple == "arm-linux-androideabi" ]]; then
        export mr_cv_target_elf=yes

        ( # subshell to avoid poluting the env.
            export gl_cv_header_working_stdint_h=yes
            export CFLAGS="$PLATFORM_CFLAGS -I${home}/$BUILD_DIR"

            mkdir ${builddir}/tools
            ln -s `which true` ${builddir}/tools/ulimit
            ln -s `which aclocal` ${builddir}/tools/aclocal-1.11
            export PATH=${builddir}/tools:$PATH

            pushd ${home}/$BUILD_DIR > /dev/null
            ${home}/$BUILD_DIR/autogen.sh --skip-gnulib &&
            popd > /dev/null &&
            ${home}/$BUILD_DIR/configure \
                --prefix=${installdir} \
                --host=${target_triple} \
                --enable-static \
                --disable-shared \
                && make && make install
            )
    else
        echo "No need to build libiconv for ${target_triple}"
        true
    fi

    local rval=$?

    popd > /dev/null
    return $rval
}

dependencies(){
    echo
}

# Let's roll.

. $SCRIPT_DIR/engine.sh
