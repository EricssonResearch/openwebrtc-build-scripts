#!/bin/bash

SCRIPT_DIR=common/scripts

. $SCRIPT_DIR/common.sh

#
# Find all files named build-<target>*.sh (except build-all*.sh) and return all <target>
#
find_all_build_targets(){
    ls build-*.sh|grep -v build-all.sh|grep -v libav|grep -v ffmpeg|grep -v osx|sed 's/build-\(.*\).sh/\1/'|sed 's/-ios//g'
}

all_build_targets(){
    for target in $(find_all_build_targets); do
	printf "%s " $target
    done
    printf "\n"
}

all_clean_targets(){
    for target in $(find_all_build_targets); do
	printf "clean-%s " $target
    done
    printf "\n"
}

#
# For the list of <target> (see above), return all <target>-ios, <target>-android etc.
#
all_build_targets_hosts(){
    for target in $(find_all_build_targets); do
	for host in $(platforms_to_build); do
	    printf "%s-%s " ${target} ${host}
	done
    done
    printf "\n"
}

all_clean_targets_hosts(){
    for target in $(find_all_build_targets); do
	for host in $(platforms_to_build); do
	    printf "clean-%s-%s " ${target} ${host}
	done
    done
    printf "\n"
}

#
# Form strings of all <target> and all <target>-<host>
#
ALL_BUILD_TARGETS_HOSTS=$(all_build_targets_hosts)
ALL_BUILD_TARGETS=$(all_build_targets)
ALL_CLEAN_TARGETS_HOSTS=$(all_clean_targets_hosts)
ALL_CLEAN_TARGETS=$(all_build_targets)

printf "all: %s\n" "$ALL_BUILD_TARGETS_HOSTS"
printf "\n"
printf "clean: %s\n" "$ALL_CLEAN_TARGETS_HOSTS"
printf "\trm -f *~ \#* core\n"
printf "\t@ ./build-all.sh -c\n"
printf "\n"
printf "fast:\n"
printf "\t@ ./build-all.sh -f\n"
printf "\n"



#
# Saying "make host" should create target for all hosts
# Example: make libnice should make libnice-ios, libnice-android, libnice-macosx, libnice-i386 and libnice-linux
#
for host in $(platforms_to_build); do
    deps_list=$(for target in $ALL_BUILD_TARGETS; do printf "%s-%s " ${target} ${host} ;done; printf "\n" )
    printf "${host}: $deps_list\n"
    printf "\n"
done

# Same for make clean-host
for host in $(platforms_to_build); do
    deps_list=$(for target in $ALL_BUILD_TARGETS; do printf "clean-%s-%s " ${target} ${host} ;done; printf "\n" )
    printf "clean-${host}: $deps_list\n"
    printf "\n"
done

#
# Saying "make target" should make all hosts for that target
# Example: "make libnice" should make all libnice-<host> for all targets
#
for target in ${ALL_BUILD_TARGETS}; do
    target_hosts=$(for host in $(platforms_to_build); do printf "%s-%s " ${target} ${host}; done; printf "\n")
    printf "${target}: ${target_hosts}\n"
    printf "\n"
done

# Same for make clean-target
for target in ${ALL_BUILD_TARGETS}; do
    target_hosts=$(for host in $(platforms_to_build); do printf "clean-%s-%s " ${target} ${host}; done; printf "\n")
    printf "clean-${target}: ${target_hosts}\n"
    printf "\n"
done

for target in ${ALL_BUILD_TARGETS}; do
    ./build-${target}*.sh -m
done
