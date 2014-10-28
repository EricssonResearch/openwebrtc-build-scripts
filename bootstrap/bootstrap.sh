#!/bin/bash -e

SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

: ${SCRIPT_REGRESSION_TEST="no"}

function install_dependencies {
    target=$2
    if [[ "$target" == "linux" ]]; then
        echo "Using \"sudo -E apt-get\" to install needed dependencies."
        sudo -E apt-get install g++ curl zlib1g-dev libpulse-dev libv4l-dev libxv-dev libgl1-mesa-dev libglu1-mesa-dev libxml-perl openjade xsltproc python-dev python2.7-dev openjdk-7-jdk subversion git gperf ruby
    fi
}

install_dependencies $@

$SCRIPT_DIR/test_internet_connection.sh || exit 1

# Use this for testing, see end of file
test_build_something_else()
{
    rm -rf good{1,2} bad1* || :
    echo build_something_else takes $@
    ./build-good1.sh $@ && \
        ./build-bad1.sh $@ && \
        ./build-good2.sh $@
}
test_verify()
{
    local has_failed_bad1="no"
    ls bad1_build_failed_on_* > /dev/null 2>&1 && has_failed_bad1="yes"
    if [[ -d good1 && -f good1/.sources_installed_tag_file.txt && -f good1/.build_successful_tag_file.txt && \
        ! -d bad1 && ${has_failed_bad1} == "yes" && ! -d good2 ]]; then
        echo "All good" >&2
    else
        echo "No, it's broken" >&2
    fi
}

build_all()
{
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
}

#engine_opts will gobble up my command line -- better save it
my_args=("$@")
. $SCRIPT_DIR/engine_opts.sh
set -- "${my_args[@]}"

if [[ ${SCRIPT_REGRESSION_TEST} != "yes" ]]; then
    build_all ${my_args[@]} || { echo "Build failed -- Use 'ls -d *build_failed*' for a quick orientation" >&2; exit 1; }
else
    test_build_something_else ${my_args[@]} || {
        echo "OK: Build intentionally failed" >&2
    }

    # Enable this for testing
    test_verify
    echo -n "Clean up test directories? [Y/n] "
    read ans
    echo $ans|grep -q '^[Nn].*' || {
        rm -rf good1 bad1_build_failed_on*
    }
fi
