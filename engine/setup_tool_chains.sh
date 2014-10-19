#!/bin/bash -e

SCRIPT_DIR="$(cd "`dirname "${BASH_SOURCE[0]}"`" && pwd)"

. $SCRIPT_DIR/common.sh

setup_ios_toolchain() {

    if [[ $(uname) == Darwin ]]; then

        echo "Setting up toolchain for ios."

        local arch=$1
        local triple=$2

        PLATFORM_IOS=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform
        PLATFORM_IOS_SDK_60=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.0.sdk
        PLATFORM_IOS_SDK_51=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk
        PLATFORM_IOS_SDK_61=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk
        PLATFORM_IOS_SDK_70=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk
        PLATFORM_IOS_SDK_71=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.1.sdk
        PLATFORM_IOS_SDK_80=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.0.sdk
        # Some patches of iOS related code needs this path to locate a patch
        PLATFORM_IOS_SIM=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform

        MIN_IOS_VERSION="5.0"
        if [ -z $SDK_IOS_VERSION ]
        then
            if [ -d $PLATFORM_IOS_SDK_80 ]
            then
                SDK_IOS_VERSION="8.0"
            elif [ -d $PLATFORM_IOS_SDK_71 ]
            then
                SDK_IOS_VERSION="7.1"
            elif [ -d $PLATFORM_IOS_SDK_70 ]
            then
                SDK_IOS_VERSION="7.0"
            elif [ -d $PLATFORM_IOS_SDK_61 ]
            then
                SDK_IOS_VERSION="6.1"
            elif [ -d $PLATFORM_IOS_SDK_60 ]
            then
                SDK_IOS_VERSION="6.0"
            elif [ -d $PLATFORM_IOS_SDK_51 ]
            then
                SDK_IOS_VERSION="5.1"
            else
                echo "ERROR: No SDK detected, looking in $PLATFORM_IOS"
                exit 1
            fi
        else
            if ! [ -d $PLATFORM_IOS/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk ]
            then
                echo "ERROR: Could not find specified SDK direction, $PLATFORM_IOS/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk"
                exit 1
            fi
        fi

        export PLATFORM_IOS_SDK="$PLATFORM_IOS/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk"
        export PLATFORM_CFLAGS="-isysroot ${PLATFORM_IOS_SDK} -miphoneos-version-min=${MIN_IOS_VERSION} -arch ${arch}"

        export CC="$(xcrun -sdk iphoneos -find clang) ${PLATFORM_CFLAGS}"
        if [[ "x$CC" == x ]] ; then
            echo "No CC for ios build found"
            exit 1
        fi

        export OBJC="$(xcrun -sdk iphoneos -find clang) ${PLATFORM_CFLAGS}"
        if [[ "x$OBJC" == x ]] ; then
            echo "No OBJC for ios build found"
            exit 1
        fi

        export CPP="$CC -E"

        export CXX="$(xcrun -sdk iphoneos -find clang++) ${PLATFORM_CFLAGS}"
        if [[ "x$CXX" == x ]]; then
            echo "No CXX for ios build found"
            exit 1
        fi

        export AS="$(xcrun -sdk iphoneos -find as)"
        if [[ "x$AS" == x ]]; then
            echo "No AS for ios build found"
            exit 1
        fi

        export FLEX_PATH="$(xcrun -sdk iphoneos -find flex)"
        if [[ "x$FLEX_PATH" == x ]]; then
            echo "No FLEX for ios build found"
            exit 1
        fi

        return 0
    else
            # Only on a Darwin OS can the iOS build be expected to succeed
        return 1
    fi
}


setup_android_toolchain() {

    if [[ $(uname) == Darwin || $(uname) == Linux ]]; then

        local arch=$1
        local triple=$2

        if ! which ndk-build ;then
            echo -e "No NDK found in path $PATH\n"
            exit 1;
        fi

        if [[ ${DX}x == x ]]; then
            local adb_path="$(which adb)"
            if [[ ${adb_path}x == x ]]; then
                echo "No adb found in path $PATH"
                exit 1
            else
                export DX="$(find $(dirname $adb_path)/../build-tools/*/dx |tail -n 1)"
            fi
        fi

        export ANDROID_NDK="$(dirname $(which ndk-build))"
        ANDROID_LEVEL="9"
        ANDROID_TOOLCHAIN_VERSION="4.8"
            # We want "darwin-x86" or "linux-x86"
        ANDROID_TOOLCHAIN_SYSTEM="$(uname|tr [A-Z] [a-z])-x86_64"

        local sysroot="${ANDROID_NDK}/platforms/android-${ANDROID_LEVEL}/arch-arm/"

        export CROSS_PREFIX="${ANDROID_NDK}/toolchains/${triple}-${ANDROID_TOOLCHAIN_VERSION}/prebuilt/${ANDROID_TOOLCHAIN_SYSTEM}/bin/${triple}-"
        export CC="${CROSS_PREFIX}gcc --sysroot=${sysroot} -fuse-ld=gold"
        export CPP="${CROSS_PREFIX}cpp --sysroot=${sysroot}"
        export CXX="${CROSS_PREFIX}g++ --sysroot=${sysroot} -fuse-ld=gold"
        export AR="${CROSS_PREFIX}ar"
        export NM="${CROSS_PREFIX}nm"
        export RANLIB="${CROSS_PREFIX}ranlib"
        export CXXCPP=$CPP

        export PLATFORM_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon -Wl,--fix-cortex-a8"
        export ANDROID_TOOLCHAIN_ROOT="${ANDROID_NDK}/toolchains/${triple}-${ANDROID_TOOLCHAIN_VERSION}/prebuilt/${ANDROID_TOOLCHAIN_SYSTEM}"
        export ANDROID_SYSROOT=${sysroot}
        return 0
    else
        # No other than Linux and Darwin hosts can build android
        return 1
    fi

}

setup_linux_toolchain() {
    unset CC CXX CPP CXXCPP AS AR NM RANLIB CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
    export PLATFORM_CFLAGS="-fPIC"
    unset PLATFORM_LDFLAGS
    echo "Trying default toolchain" >&2
}

setup_osx_toolchain() {

    local sdkroot="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk"

    export PLATFORM_CFLAGS="-isysroot ${sdkroot} -mmacosx-version-min=10.7 -arch x86_64 -m64"

    export CC="$(xcrun -sdk macosx -find clang) ${PLATFORM_CFLAGS}"
    if [[ "x$CC" == x ]] ; then
        echo "No CC for macosx build found" >&2
        exit 1
    fi

    export OBJC="$(xcrun -sdk macosx -find clang) ${PLATFORM_CFLAGS}"
    if [[ "x$OBJC" == x ]] ; then
        echo "No OBJC for macosx build found" >&2
        exit 1
    fi

    export CPP="$CC -E"

    export CXX="$(xcrun -sdk macosx -find clang++) ${PLATFORM_CFLAGS}"
    if [[ "x$CXX" == x ]]; then
        echo "No CXX for macosx build found" >&2
        exit 1
    fi

    export AS="$(xcrun -sdk macosx -find as)"
    if [[ "x$AS" == x ]]; then
        echo "No AS for macosx build found" >&2
        exit 1
    fi

    export FLEX_PATH="$(xcrun -sdk macosx -find flex)"
    if [[ "x$FLEX_PATH" == x ]]; then
        echo "No FLEX for macosx build found" >&2
        exit 1
    fi

    unset CXXCPP AR NM RANLIB CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
    unset PLATFORM_LDFLAGS
}

setup_ios-simulator_toolchain() {
    local arch=$1

    export PLATFORM_IOS_SIM=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform
    export PLATFORM_IOS_SDK=`find -s "$PLATFORM_IOS_SIM/Developer/SDKs" -iname iPhoneSimulator[7\|8]*.sdk -maxdepth 1 | tail -1`
    MIN_IOS_VERSION="5.0"

    export PLATFORM_CFLAGS="-isysroot ${PLATFORM_IOS_SDK} -mios-simulator-version-min=${MIN_IOS_VERSION} -arch ${arch}"

    export CC="$(xcrun -sdk iphonesimulator -find clang) ${PLATFORM_CFLAGS}"
    if [[ "x$CC" == x ]] ; then
        echo "No CC for ios simulator build found" >&2
        exit 1
    fi

    export OBJC="$(xcrun -sdk iphonesimulator -find clang) ${PLATFORM_CFLAGS}"
    if [[ "x$OBJC" == x ]] ; then
        echo "No OBJC for ios simulator build found" >&2
        exit 1
    fi

    export CPP="$CC -E"

    export CXX="$(xcrun -sdk iphonesimulator -find clang++) ${PLATFORM_CFLAGS}"
    if [[ "x$CXX" == x ]]; then
        echo "No CXX for ios simulator build found" >&2
        exit 1
    fi

    export AS="$(xcrun -sdk iphonesimulator -find as)"
    if [[ "x$AS" == x ]]; then
        echo "No AS for ios simulator build found" >&2
        exit 1
    fi

    export FLEX_PATH="$(xcrun -sdk iphonesimulator -find flex)"
    if [[ "x$FLEX_PATH" == x ]]; then
        echo "No FLEX for ios simulator build found" >&2
        exit 1
    fi

    export PLATFORM_CFLAGS="${PLATFORM_CFLAGS} -Wl,-no_compact_unwind -Qunused-arguments"
}
