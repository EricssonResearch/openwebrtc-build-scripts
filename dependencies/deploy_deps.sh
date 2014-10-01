#!/bin/bash

plat_ios=armv7-ios
plat_android=armv7-android
plat_osx=x86_64-osx
plat_linux=x86_64-linux
plat_ios_simulator=i386-ios-simulator

for p in ios android osx linux ios_simulator; do
    eval plat='$'"plat_$p"
    if [[ ! -e openwebrtc-deps-$plat.tgz ]] ; then
        echo "The file openwebrtc-deps-$plat.tgz is missing, not deployed"
    else
        echo "Deploying openwebrtc-deps-$plat to"
        if [[ -d ../../openwebrtc ]] ; then
            echo "../../openwebrtc"
            rm -rf ../../openwebrtc/openwebrtc-deps-$plat/
            tar -C ../../openwebrtc -xzf openwebrtc-deps-$plat.tgz || exit 1
        elif [[ -d ../../../openwebrtc ]]; then
            echo "../../../openwebrtc"
            rm -rf ../../../openwebrtc/openwebrtc-deps-$plat/
            tar -C ../../../openwebrtc -xzf openwebrtc-deps-$plat.tgz || exit 1
        fi
    fi
done
