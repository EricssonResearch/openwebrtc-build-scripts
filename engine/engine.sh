if [ -z "$BUILD_DIR" ]; then
    echo "BUILD_DIR should be set in $0"
    exit 1
fi

if [ -z "$SCRIPT_DIR" ]; then
    echo "SCRIPT_DIR should be set in $0"
    exit 1
fi

. $SCRIPT_DIR/engine_opts.sh
. $SCRIPT_DIR/setup_tool_chains.sh

sha_sum()
{
    local s=$(shasum $1|awk '{print $1}')
    echo $s
}

#
# Function definitions
#

failed_build_dir_name(){
    local date_string=$(date +"%y%m%d-%H:%M:%S")
    local sha_sum_of_script=$(sha_sum $0)
    local dir_name=${BUILD_DIR}_build_failed_on_${date_string}_using_script_with_md5sum_${sha_sum_of_script}
    echo $dir_name
}

move_failed_build_dir(){
    if [[ -d $BUILD_DIR && $BUILD_DIR != "." ]]; then
	echo mv $BUILD_DIR $(failed_build_dir_name)
	mv $BUILD_DIR $(failed_build_dir_name)
    fi
}

trap 'move_failed_build_dir' ERR

help_engine(){
    echo help for engine_sh
}

die_engine(){
    echo "ERROR: $1"
    exit 1
}

current_script_id(){
    echo $(sha_sum $1)
}

mark_sources_installed(){
    [[ $# != 2 ]] && {
	echo "ERROR: mark_sources_installed takes two arguments, arguments received were $@" >&2
	exit 1
    }
    local source_dir=$1
    local git_branch=$2
    local script_id=$(current_script_id $0)
    echo "Marking sources installed in $BUILD_DIR" >&2
    (cd $source_dir && git checkout ${git_branch} ) || {
	echo "ERROR: Failed to checkout the master branch from the git at $source_dir" >&2
	exit 1
    }
    echo $script_id > $BUILD_DIR/.sources_installed_tag_file.txt
    (cd $source_dir && git add .sources_installed_tag_file.txt && git commit --no-verify -m "tag file identifying the build script that installed the sources")|| {
	echo "ERROR: Failed to add or commit the .sources_installed_tag_file.txt to the git" >&2
	exit 1
    }
}

configure_source_git(){
   if [[ $# != 2 ]]; then
	    echo "ERROR: configure_source_git takes two arguments, arguments received were $@" >&2
	    exit 1
    fi
    local source_dir=$1
    if ! [[ -d $source_dir ]]; then
		echo "ERROR: The source directory $1 does not exist (when at $(pwd))" >&2
		exit 1
    fi
    local git_branch=$2
    if ! dir_contains_git $source_dir; then
	create_git $source_dir || {
	    echo "ERROR: Failed to create git at $source_dir" >&2
	    exit 1
	}
    fi

    mark_sources_installed $source_dir $git_branch

    if dir_contains_git $source_dir; then
	for host in $(platforms_to_build); do
	    (cd $source_dir && git branch -f $(get_target_triple $host)) || {
		echo "ERROR: Problems creating branch $(get_target_triple $host) in $source_dir for $host" >&2
		exit 1
	    }
	done
    else
	echo "ERROR: Directory $source_dir is not a git. This is an internal error"
	exit 1
    fi
}

sources_installed(){
    if [[ -z $1 ]]; then
	echo "ERROR: sources_installed takes one argument" >&2
	exit 1
    fi

    if [[ $(type -t "local_sources_installed") == "function" ]]; then
        local_sources_installed
    else
        local dir=$1
        local script_id=$(current_script_id $0)
        [[ -d $dir ]] && dir_contains_git $dir  && [[ -f $BUILD_DIR/.sources_installed_tag_file.txt ]] && [[ $script_id == $(cat $BUILD_DIR/.sources_installed_tag_file.txt) ]]
    fi
}

#FIXME: Make this mark the build in the build directory instead
mark_build_successful(){
    local script_id=$(current_script_id $0)
    echo "Marking build successful in $BUILD_DIR" >&2
    echo $script_id > $BUILD_DIR/.build_successful_tag_file.txt
}

setup() {
    target_triple=$2
    # these cannot be local since they are used when building
    builddir=$(pwd)/build/${target_triple}/$BUILD_DIR
    installdir="$(pwd)/out/${target_triple}/$BUILD_DIR"

    mkdir -p "${builddir}"
    mkdir -p "${installdir}"
}

clean_build(){
    for host in $@; do
	local target_triple=$(get_target_triple $host)
	if [[ -z $target_triple ]]; then
	    echo "Could not find target_triple for $host"
	    return 1
	fi

        (
            for f in build out; do
                if cd $f/${target_triple}/$BUILD_DIR 2> /dev/null; then
                    local p=$(pwd)
                    cd - > /dev/null
                    rm -fr $p
                fi
            done
            )

    done
}

clean_source(){
	echo "clean_source, $(pwd)"
    if [[ $(type -t "local_clean_source") == "function" ]]; then
        local_clean_source
    else
        echo "Cleaning source in $BUILD_DIR"
        rm -fr $BUILD_DIR
    fi
}

clean() {
    clean_source && clean_build $@
}

dir_contains_git(){
    if [[ -z $1 ]]; then
	echo "ERROR: dir_contains_git takes one argument"
	exit 1
    fi
    local dir=$1
    (cd $dir;
	[[ $(git rev-parse --show-toplevel) == $(pwd -P) ]]
	)
}

create_git() {
    echo "Creating git in $1" >&2
    if [[ -z $1 ]]; then
	echo "ERROR: create_git takes one argument" >&2
	exit 1
    fi
    local dir=$1
    (cd $dir; git init && git add . && git commit --no-verify -a -m "Init")
}

create_git_if_necessary() {
    if [[ $(git rev-parse --show-toplevel) != $(pwd -P) ]]; then
	git init
	git add .
	git commit --no-verify -a -m "Init"
    fi

}


require_functions(){
#
# Require that each argument given is a defined function in the current shell
#
    for function in $@; do
	[[ $(type -t $function) == "function" ]]   || die_engine "The function \”$function\” is required but not defined"
    done
}

#
# Execute accordingly
#

if [[ $do_precond == "yes" ]]; then
    if [[ $opt_n == "yes" ]]; then
        echo "PRECONDITIONS"
    else
        check_preconditions $all_args
    fi
fi

if [[ $do_clean_build == "yes" ]]; then
    if [[ $opt_n == "yes" ]]; then
	echo "CLEAN BUILD (${platforms})"
    else
	if [ -d $BUILD_DIR ]; then
	    clean_build $(platforms_to_build)
	fi
    fi
    if [[ $opt_b != "yes" && $do_clean_source != "yes" ]]; then
	if [[ $opt_n == "yes" ]]; then
	    echo "EXIT"
	fi
	exit 0
    fi
fi

if [[ $do_clean_source == "yes" ]]; then
    if [[ $opt_n == "yes" ]]; then
	echo "CLEAN BUILD $(platforms_to_build)"
	echo "CLEAN SOURCE"
    else
	if [ -d $BUILD_DIR ]; then
	    clean_build $(platforms_to_build)
	    clean_source
	fi
    fi
    if [ $opt_b != "yes" ]; then
	if [[ $opt_n == "yes" ]]; then
	    echo "EXIT"
	fi
	exit 0
    fi
fi

if [[ $do_install == "yes" ]]; then
    if sources_installed $BUILD_DIR; then
	if [[ $opt_n == "yes" ]]; then
	    echo "INSTALL SOURCES (already installed)"
	fi
	#
	# If sources are installed we do nothing
	#
    else
	if [[ $opt_n == "yes" ]]; then
	    echo "INSTALL SOURCES"
	else
		if [[ -z $BRANCH ]] ; then
			git_branch=master
		else
			git_branch=$BRANCH
		fi
	    clean_source && install_sources && configure_source_git $BUILD_DIR ${git_branch} && {
		[[ $(type -t patch_sources) == function ]] && {
		    for p in $(platforms_to_build); do
			triple=$(get_target_triple $p) && arch=$(get_architecture $p) ||{
			    echo "ERROR: Failed to establish achitecture and triple for platform $p" >&2
			    exit 1
			}
			(
			        patch_sources ${arch} ${triple} || {
				    echo "ERROR: Failed to patch sources for ${arch} ${triple}" >&2
				    exit 1
			        } || true
		            ) || exit 1
		    done
		} || true
	    } || {
		echo "ERROR: Failed to install sources and configure source git" >&2
		exit 1
	    }
	fi
    fi
fi

if [[ $do_build == "yes" ]]; then
    for p in ${platforms}; do
	triple=$(get_target_triple $p)
	if [[ $? != 0 ]]; then
	    echo "Could not get target triple for $p"
	    exit 1
	fi

	arch=$(get_architecture $p)
	if [[ $? != 0 ]]; then
	    echo "Could not get architecture for $p"
	    exit 1
	fi

	if [[ $opt_n == "yes" ]]; then
	    echo "BUILD ${arch} ${triple}"
	else
	    (
		setup_${p}_toolchain ${arch} ${triple} && {
		    setup ${arch} ${triple}
		    build ${arch} ${triple} && mark_build_successful || exit
                } || true
		) || exit
	fi
    done
fi

if [[ $do_makefile == "yes" ]]; then
    if [[ $opt_n == "yes" ]]; then
	echo "MAKEFILE"
    else
	if [[ $0 == *ios.sh ]]; then
	    self_name=$(echo $0|sed 's/.*build-\(.*\)-ios.sh/\1/')
	else
	    self_name=$(echo $0|sed 's/.*build-\(.*\)\.sh/\1/')
	fi
	self_name_hosts=$(for host in $(platforms_to_build); do printf "%s-%s " ${self_name} ${host}; done; printf "\n")
	all_target_hosts=$(for host in $(platforms_to_build); do printf "${self_name}-${host}"; done; printf "\n")

	printf "%s: %s\n" ${self_name} "${self_name_hosts}"
	for host in $(platforms_to_build); do
	    deps=$(for dep in $(dependencies); do printf "%s-%s " ${dep} ${host}; done; printf "\n")

	    printf "${self_name}-${host}: build/$(get_target_triple $host)/${BUILD_DIR}/done\n\n"
	    printf "build/$(get_target_triple $host)/${BUILD_DIR}/done: $deps\n"
	    printf "\t$0 ${host}\n"
	    printf "\ttouch build/$(get_target_triple $host)/${BUILD_DIR}/done\n"
	    printf "\n"
	    printf "clean-${self_name}-${host}:\n"
	    printf "\t$0 -c ${host}\n"
	    printf "\n"
	done

    fi
fi
