#!/bin/bash -e

LIBFFI_VERSION=3.0.13

#git clone git://github.com/landonf/libffi-ios.git
#pushd libffi-ios
#patch -p1 < ../libffi_missing_cname.patch
#./build-ios.sh
#popd

BUILD_DIR=libffi
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 - Internet connection is broken."
}

install_sources() {
    git clone git://github.com/atgreen/libffi.git $BUILD_DIR
    (
        cd $BUILD_DIR
        git reset --hard v$LIBFFI_VERSION || die "Could not reset git to v$LIBFFI_VERSION"
        curl -o ffi_android.patch https://github.com/netjunki/jna-android/commit/e8328d86af536b3d491c412fd9c4c202ddb156c2.patch
        git am -p3 --include *closures* ffi_android.patch || die "$0 - Could not apply patch."
    )
}

patch_sources() {
    local arch=$1
    local target_triple=$2
    local home=$(pwd)

    echo "No patching needed for ${target_triple}"

    (
        # lets do this to make sure we are all setup with branches.
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
        git checkout $target_triple || {
            echo "ERROR: Could not checkout ${target_triple} in ${home}"
            exit 1
        }
        )

    pushd ${builddir} > /dev/null
    rm -fr ./$BUILD_DIR && cp -R ${home}/$BUILD_DIR/* .

    if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
        # need to apply specific patch to sources to build for ios
        patch -p1 < ${home}/libffi-${LIBFFI_VERSION}_ios_build.patch

        mkdir -p build_simulator
        python generate-ios-source-and-headers.py
        pushd build_ios > /dev/null

        ( # subshell to avoid poluting the shell

            export CFLAGS=$PLATFORM_CFLAGS
            make && make install
        )

        local rval=$?
        popd > /dev/null

        # current workaround is to copy installed file to correct place instead of patching libffi python script.
        cp -R ${builddir}/armv7-ios/* ${installdir}

    elif [[ ${target_triple} == "i386-apple-darwin10" ]]; then

        patch -p1 < ${home}/libffi-${LIBFFI_VERSION}_ios_build.patch

        mkdir -p build_ios # disables build for device
        python generate-ios-source-and-headers.py
        pushd build_simulator > /dev/null

        (
            export CFLAGS=$PLATFORM_CFLAGS
            make && make install
            )
        local rval=$?
        popd > /dev/null

        # current workaround is to copy installed file to correct place instead of patching libffi python script.
        cp -R ${builddir}/i386-ios/* ${installdir}
    else
        if [[ ${target_triple} == "arm-linux-androideabi" ]]; then
            local platform_configure_flags="--host=${target_triple}"
            export CFLAGS="$PLATFORM_CFLAGS -DFFI_MMAP_EXEC_WRIT=1"
        else
            local platform_configure_flags=""
            export CFLAGS=$PLATFORM_CFLAGS
        fi

        ( # subshell to avoid polution
            ./configure \
                ${platform_configure_flags} \
                --prefix=${installdir} \
                --enable-static \
                --disable-shared \
                && make && make install
            )

        local rval=$?
    fi

    popd > /dev/null
    return $rval
}

dependencies(){
    echo
}

# Let's roll.
. $SCRIPT_DIR/engine.sh
