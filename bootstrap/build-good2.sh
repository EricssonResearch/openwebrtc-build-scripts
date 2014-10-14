#!/bin/bash -e

GOOD2_VERSION=1.0.0

BUILD_DIR=good2
SCRIPT_DIR=../engine
: ${PREFIX:=~/.openwebrtc}

export PATH=$PREFIX/bin:$PATH

check_preconditions() {
    :
}

local_clean_source() {
    echo "Cleaning ${BUILD_DIR}"
    rm -fr $BUILD_DIR
}

install_sources() {
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR > /dev/null

    # get xz
    cat <<EOF > build.sh
#!/bin/bash
echo Installing sources for good 2
true
EOF
    chmod +x build.sh
    popd > /dev/null
}

build() {
    (
        pushd ${BUILD_DIR} > /dev/null
        ./build.sh; rc=$?
        popd > /dev/null
        return $rc
        )
}


# drive
. $SCRIPT_DIR/engine.sh
