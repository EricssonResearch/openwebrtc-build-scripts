#!/bin/bash -e
#
# Common build environment
#

export PATH=~/.openwebrtc/bin:$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin

die() {
    echo "$@" >&2
    exit 1
}

all_platforms(){
    echo ios android ios-simulator osx linux
}

platforms_to_build(){
    case $(uname) in
        (Linux) echo "android linux";;
        (Darwin) echo "ios android osx ios-simulator";;
        (*) echo "";;
    esac
}

get_target_triple() {
    local platform=$1
    case $platform in
        ios) echo "arm-apple-darwin10" ;;
        android) echo "arm-linux-androideabi" ;;
        osx) echo "x86_64-apple-darwin" ;;
        ios-simulator) echo "i386-apple-darwin10" ;;
        linux) echo "x86_64-unknown-linux" ;;
        *) echo "Unknown" ; return 1 ;;
    esac
}

get_architecture() {
    local platform=$1
    case $platform in
        ios) echo "armv7";;
        android) echo "arm";;
        osx) echo "x86_64";;
        ios-simulator) echo "i386";;
        linux) echo "x86_64";;
        *) echo "Unknown" ; return 1;;
    esac
}

target_from_target_triple(){
    local target_triple=$1
    case $target_triple in
        arm-apple-darwin10) echo armv7-ios;;
        arm-linux-androideabi) echo armv7-android;;
        x86_64-apple-darwin) echo x86_64-osx;;
        x86_64-unknown-linux) echo x86_64-linux;;
        i386-apple-darwin10) echo i386-ios-simulator;;
        *)
            echo "unknown-unknown-unknown"
            echo "Could not find target triple $target_triple in $FUNCNAME" &>2
            return 1
    esac
}

arch_from_dep(){
    local dep=$1
    case $dep in
        armv7-ios) echo ios;;
        armv7-android) echo android;;
        x86_64-osx) echo osx;;
        x86_64-linux) echo linux;;
        i386-ios-simulator) echo ios-simulator;;
        *)
            echo "unknown-unknown"
            echo "ERROR: $dep not found in $FUNCNAME" >&2
            return 1
            ;;
    esac
}
