show_help(){
    echo "Usage: $0 [-h] [-f] [-c] [-C] [-p] [-b] [-i] [-m] [-D] [-B] (-r | -d) <platform ...>"
    echo " -h : Help. Shows this text and exits"
    echo " -f : Fast mode. Do not download, unpack, check out or patch code. This cannot be combined with -c"
    echo " -c : Clean builds. Remove old builds. If platforms are given, only those platforms are affected, otherwise all platforms are affected"
    echo " -C : Clean sources. Remove old sources. This implies removing old builds aswell for all platforms, even if platforms are given."
    echo " -p : Check Preconditions and exit"
    echo " -b : Build. This options is implicit, but must be given explicitely when -c is used."
    echo " -i : Install sources only, don't build"
    echo " -m : Generate makefile fragment for building this part of the code. Mutually exclusive with all other options"
    echo " -D : Debug. Be verbose about how things happen"
    echo " -B : Show the build directory and exit"
    echo " -r : Build release optimized code if possible"
    echo " -d : Build debug optimized code if possible"
    echo " <platform ...> A space separated list of platforms to build for, currently ios and android are supported for"
    echo "                dependencies. Your native platform (osx or linux) is the choice for bootstrap"
}

die(){
    echo "$@" >&2
    exit 1
}

dbg_dump_options(){
    if [[ ! -n $opt_D ]]; then
    cat <<EOF
$1
Options:
==========
opt_h: $opt_h
opt_f: $opt_f
opt_c: $opt_c
opt_C: $opt_C
opt_p: $opt_p
opt_b: $opt_b
opt_i: $opt_i
opt_m: $opt_m
opt_n: $opt_n
opt_r: $opt_r
opt_d: $opt_d
opt_D: $opt_D
opt_B: $opt_B
==========
EOF
    fi
}
all_args=$@
opt_h="no"    # Help
opt_f="no"    # Fast build, no download
opt_c="no"    # Clean builds
opt_C="no"    # Clean sources (and all builds)
opt_p="no"    # Preconditions
opt_b="no"    # Build
opt_i="no"    # Install (only)
opt_m="no"    # Makefile-fragment
opt_n="no"    # Dryrun -- only say what would be done
opt_r="no"    # Build release optimized code if possible
opt_d="no"    # Build debug optimized code if possible
opt_D="no"    # Debug build script
opt_B="no"    # Show build directory and exit
errcode=""
args=$(getopt hfcCpbimnrdDB "$@");errcode=$?;set -- $args
[ X$errcode != X0 ] && exit 1
while [ $# -gt 0 ]
do
    case "$1" in
	(-h) show_help
	exit 1
	;;
	(-f) opt_f=yes;;
	(-c) opt_c=yes;;
	(-C) opt_C=yes;;
	(-p) opt_p=yes;;
	(-b) opt_b=yes;;
	(-i) opt_i=yes;;
	(-m) opt_m=yes;;
	(-n) opt_n=yes;;
	(-r) opt_r=yes;;
	(-d) opt_d=yes;;
	(-D) opt_D=yes;;
	(-B) opt_B=yes;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*)  break;;
    esac
    shift
done

platforms="$*"

dbg_dump_options "After parsing options"


#
# -B means to show BUILD_DIR and then exit
#

if [[ $opt_B == yes ]]; then
    echo $BUILD_DIR
    exit
fi

#
# -m is mutually exclusive with all others (except -n)
#

if [[ $opt_m == yes && ( $opt_f == yes || $opt_c == yes || $opt_C == yes || $opt_r == yes || $opt_d == yes || $opt_p == yes || $opt_b == yes || $opt_i == yes ) ]]; then
    echo "-m cannot be combined with any other option"
    show_help
    exit
fi

#
# -r and -d are mutually exclusive
#
if [[ $opt_r == yes && $opt_d == yes ]]; then
    echo "Options -r and -d are mutually exclusive"
    show_help
    exit 1
fi

#
# When building, either option -d or option -r must be given
#
if [[ $opt_r == no && $opt_d == no &&  ( $opt_i == no && ( $opt_c == no && $opt_C == no || $opt_b == yes) ) ]]; then
    echo "When building, either option -d or option -r must be given"
    show_help
    exit 1
fi

#
# -f and -c are mutually exclusive
#
if [[ $opt_f == yes && $opt_c == yes ]]; then
    echo "Options -f and -c are mutually exclusive"
    show_help
    exit 1
fi

#
# -f and -i are mutually exclusive
#
if [ $opt_f == "yes" -a $opt_i == "yes" ]; then
    echo "Options -f and -i are mutually exclusive"
    show_help
    exit 1
fi

# -p turns off -b and -r
if [[ $opt_p == yes ]]; then
    opt_b="no"
    opt_r="no"
    opt_d="yes"
fi

if [ $opt_D == "yes" ]; then
    echo Options are:
    echo opt_h: $opt_h
    echo opt_f: $opt_f
    echo opt_c: $opt_c
    echo opt_p: $opt_p
    echo opt_b: $opt_b
    echo opt_i: $opt_i
    echo opt_m: $opt_m
    echo opt_n: $opt_n
    echo opt_D: $opt_D
fi

do_precond="yes"

if [[ $opt_m == "yes" ]]; then
#
# Make, or...
#
    do_makefile="yes"
    do_clean_build="no"
    do_clean_source="no"
    do_install="no"
    do_build="no"
    do_release="no"
else
#
# ... no make
#
    do_makefile="no"

    if [[ $opt_c == "yes" ]]; then
	do_clean_build="yes"
	do_precond="no"
    else
	do_clean_build="no"
    fi

    if [[ $opt_C == yes ]]; then
	do_clean_source="yes"
	do_precond="no"
    else
	do_clean_source="no"
    fi

    if [[ $opt_b == yes ]]; then
        do_precond="yes"
    fi

    if [[ $opt_f == "yes" ]]; then
	do_install="no"
    else
	do_install="yes"
    fi

    if [[ $opt_b == "yes" || ( $opt_C != "yes" && $opt_c != "yes" && $opt_p != "yes" && $opt_i != "yes" && $opt_m != "yes" && $opt_n != "yes" ) ]]; then
	do_build="yes"
    else
	do_build="no"
    fi

    if [[ $opt_r == "yes" ]]; then
        do_release="yes"
    fi
fi

if [[ $opt_D == "yes" ]]; then
    echo do_precond: $do_precond
    echo do_clean_build:  $do_clean_build
    echo do_clean_source: $do_clean_source
    echo do_install: $do_install
    echo do_build: = $do_build
    echo do_makefile : $do_makefile
fi

#
# For debugging purposes we have a special environment variable that can be used to turn on
# the -n flag
#

if [[ $DRYRUN == "yes" ]]; then
    opt_n="yes"
fi
