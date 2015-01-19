#!/bin/bash -e

LIBVPX_VERSION="1.3.0"

BUILD_DIR=libvpx
SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

check_preconditions() {
    $SCRIPT_DIR/test_internet_connection.sh || die "$0 -- Internet connection is broken."
}

install_sources() {
    git clone https://chromium.googlesource.com/webm/libvpx $BUILD_DIR
    pushd $BUILD_DIR > /dev/null
    git reset --hard v$LIBVPX_VERSION

    # Save NEON registers in VP8 NEON functions
    git cherry-pick 33df6d1fc1d268b4901b74b4141f83594266f041 || die "Failed to cherry-pick patch"
    popd > /dev/null
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
        if [[ $target_triple == "x86_64-apple-darwin" ]]; then
            git apply ../libvpx_0001_MacOSX_Mavericks_SDK.patch || {
                echo "ERROR: Could not patch ${target_triple} in $(pwd) for Mavericks SDK"
                exit 1
            }
            git commit -a --no-verify -m "Using correct SDK for Mac OS X Mavericks"
        fi
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

    (
     cd ${builddir}

     export CFLAGS="$CFLAGS $PLATFORM_CFLAGS"
     if [[ ${target_triple} == "arm-apple-darwin10" ]]; then
         local modified_target_triple="armv7-darwin-gcc"
         local extra_configure_flags="--target=${modified_target_triple} --libc=$PLATFORM_IOS_SDK"
         export LDFLAGS="-arch armv7"
     elif [[ $target_triple == "i386-apple-darwin10" ]]; then
         export CC=clang
         export LD=clang
         export CXX=clang++
         unset CFLAGS
         unset CXXFLAGS
         unset CPPFLAGS
         unset AS
         local modified_target_triple="x86-darwin10-gcc"
         local extra_configure_flags="--sdk-path=${PLATFORM_IOS_SIM}/Developer --target=${modified_target_triple}"
     elif [[ $target_triple == "x86_64-apple-darwin" ]]; then
         export CC=clang
         export LD=clang
         export CXX=clang++
         unset AS
         unset CFLAGS
         unset CXXFLAGS
         unset CPPFLAGS
     elif [[ ${target_triple} == "arm-linux-androideabi" ]]; then
         export CFLAGS="$CFLAGS -I${ANDROID_NDK}/sources/android/cpufeatures"
         export LDFLAGS="-L${builddir} ${builddir}/cpufeatures.o"

         ln -s ${ANDROID_SYSROOT}/usr/lib/libc.so ${builddir}/libpthread.so
         $CC $CFLAGS -c -o ${builddir}/cpufeatures.o ${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c
         local modified_target_triple="armv7-android-gcc"
         local extra_configure_flags="--sdk-path=${ANDROID_NDK} --target=${modified_target_triple} --disable-runtime-cpu-detect"
     else
	 export CFLAGS="$CFLAGS $PLATFORM_CFLAGS -fvisibility=hidden"
     fi

     ${home}/$BUILD_DIR/configure \
         --prefix=${installdir} \
         --enable-static \
         --disable-shared \
         --enable-pic \
         --enable-vp8 \
         --disable-vp9 \
         --enable-error-concealment \
         --enable-realtime-only \
         --extra-cflags="-O1" \
         --disable-examples ${extra_configure_flags} \
         && make && make install

     )

}

dependencies(){
    echo
}

# All setup, let's roll.
. $SCRIPT_DIR/engine.sh
