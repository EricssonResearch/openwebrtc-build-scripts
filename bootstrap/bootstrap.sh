#!/bin/bash -e

SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

function install_dependencies {
    target=$2
    if [[ "$target" == "linux" ]]; then
        echo "Using \"sudo -E apt-get\" to install needed dependencies."
        sudo -E apt-get install g++ curl zlib1g-dev libpulse-dev libv4l-dev libxv-dev libgl1-mesa-dev libglu1-mesa-dev libxml-perl openjade xsltproc python-dev python2.7-dev openjdk-7-jdk subversion git gperf
    fi
}

install_dependencies $@

$SCRIPT_DIR/test_internet_connection.sh || exit 1


./build-xz.sh $@ && \
./build-m4.sh $@ && \
./build-autoconf.sh $@ && \
./build-automake.sh $@ && \
./build-libtool.sh $@ && \
./build-pkg-config.sh $@ && \
./build-intltool.sh $@ && \
./build-libxml2.sh $@ && \
./build-gettext.sh $@ && \
./build-gtk-osx-docbook.sh $@ && \
./build-gtk-doc.sh $@ && \
./build-libffi.sh $@ && \
./build-glib.sh $@ && \
./build-bison.sh $@ && \
./build-flex.sh $@ && \
./build-gnome-common.sh $@ && \
./build-gobject-introspection.sh $@ && \
./build-pygobject.sh $@ && \
./build-python-twisted.sh $@ && \
./build-yasm.sh $@ && \
./build-nasm.sh $@ && \
./build-graphviz.sh $@ && \
./build-webkit-style-check.sh $@

. $SCRIPT_DIR/engine_opts.sh
