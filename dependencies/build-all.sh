#!/bin/bash -e

SCRIPT_DIR=../engine

$SCRIPT_DIR/test_internet_connection.sh || exit 1

if [[ ! -d ~/.openwebrtc ]] ; then
    # FIXME : check environment tool versions and re-run bootstrap if they are
    # not present or outdated
    echo "Environment not set up. Bootstrapping..."
    pushd ../bootstrap > /dev/null
    ./bootstrap.sh $@
    popd > /dev/null
fi

./build-libusrsctp.sh $@  && \
./build-readline.sh $@ && \
./build-zlib.sh $@ && \
./build-libxml2.sh $@ && \
./build-libiconv.sh $@ && \
./build-gettext.sh $@ && \
./build-sqlite.sh $@ && \
./build-libffi.sh $@ && \
./build-glib.sh $@ && \
./build-girepository.sh $@ && \
./build-gmp.sh $@ && \
./build-nettle.sh $@ && \
./build-gnutls.sh $@ && \
./build-glib-networking.sh $@ && \
./build-libsoup.sh $@ && \
./build-json-glib.sh $@ && \
./build-orc.sh $@ && \
./build-libopus.sh $@ && \
./build-libvpx.sh $@ && \
./build-openssl.sh $@ && \
./build-libsrtp.sh $@ && \
./build-openh264.sh $@ && \
./build-gstreamer.sh $@ && \
./build-gst-plugins-base.sh $@ && \
./build-gst-plugins-good.sh $@ && \
./build-gst-plugins-bad.sh $@ && \
./build-libnice.sh $@ && \
./build-icu.sh $@ && \
./build-javascriptcoregtk.sh $@ && \
./build-seed.sh $@ && \
./build-openwebrtc-gst-plugins.sh $@ || exit 1

. $SCRIPT_DIR/engine_opts.sh

if [ $do_build == "yes" ]; then
    ./create_file_release.sh $@ || die "$0 -- Could not create file release."
fi
