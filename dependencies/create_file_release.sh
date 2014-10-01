#!/bin/bash -e

SCRIPT_DIR=../engine

. $SCRIPT_DIR/common.sh

die(){
    echo "$@" >&2
    exit 1
}

echo "Creating file releases for platforms $@"
platforms=$@

copy_files() {
    local platform=$1
    local target_triple=$(get_target_triple $platform)
    local folder_base_name="openwebrtc-deps-"

    # FIXME: This hard codes the armv7 and x86_64 prefixes for file releases.
    if [[ $platform == "ios" || $platform == "android" ]]; then
	local folder_name="${folder_base_name}armv7-$platform"
    elif [[ $platform == "ios-simulator" ]]; then
        local folder_name="${folder_base_name}i386-$platform"
    else
	local folder_name="${folder_base_name}x86_64-${platform}"
    fi

    if [[ -f ${folder_name}.tgz ]]; then
        echo "File release exists. Please remove old file release if you want to create a new one."
        exit 1
    fi

    mkdir -p ${folder_name}
    local home=$(pwd)
    pushd out/$target_triple > /dev/null
    for f in $(ls -d *); do
	cd $f
	if [[ $platform == "osx" ]]; then
		local files=$(find . \( -name '*.a' -o -name '*.h' \) -a ! -name '*icu*')
	else
		local files=$(find . \( -name '*.a' -o -name '*.h' \))
	fi
	for file in $files; do
	    local dir=$(dirname $file)
	    mkdir -p ${home}/${folder_name}/$dir
	    cp -v $file ${home}/${folder_name}/$dir
	done
	cd ..
    done
    popd > /dev/null

    cp $folder_name/lib/glib-2.0/include/glibconfig.h $folder_name/include/glib-2.0/
    mkdir -p $folder_name/include/private-gstreamer

    cp libnice/gst/gstnice*.h $folder_name/include/private-gstreamer/
    #replace c++ comments with c comments.
    perl -pi -e "s,endif //(.*),endif /*\1 */,g" $folder_name/include/private-gstreamer/gstnicesrc.h

    echo "Adding platform specific objects to file release."

    if [[ $target_triple == "arm-apple-darwin10" ]]; then
        for f in my_environ.o my_stat.o ; do
            if [[ -f build/$target_triple/glib/$f ]]; then
                echo "cp build/$target_triple/glib/$f $folder_name/lib"
                cp build/$target_triple/glib/$f $folder_name/lib
            else
                echo "Not adding $f to file release since it could not be found!"
            fi
        done
    fi

    tar -czvf ${folder_name}.tgz ${folder_name} || die "Could not create tarball using folder ${folder_name}"
}

for platform in $platforms; do
    echo "Creating file release for $platform"
    copy_files $platform
done

echo "Done, existing file release(s) (should be atleast one for the specified platform(s): $@):"
find . -name 'openwebrtc-deps*.tgz' -ls
