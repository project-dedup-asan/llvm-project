#!/usr/bin/env bash

FORCE=
INSTALL_DIR=$HOME/opt
BUILD_DIR_BASENAME=build
JOBS_PARALLEL=8

say() {
    [ -t 2 ] && [ -n "$TERM" ] \
        && echo "$(tput setaf 7)$*$(tput sgr0)" \
        || echo "$*"
}

info() {
    [ -t 2 ] && [ -n "$TERM" ] \
        && echo "$(tput setaf 2)$*$(tput sgr0)" \
        || echo "$*"
}

err() {
    [ -t 2 ] && [ -n "$TERM" ] \
        && echo "$(tput setaf 1)$*$(tput sgr0)" \
        || echo "$*"
}

warn() {
    [ -t 2 ] && [ -n "$TERM" ] \
        && echo "$(tput setaf 3)$*$(tput sgr0)" \
        || echo "$*"
}

# Can be called at top-level `llvm-project` of `llvm-project/scripts`
switch_to_llvm_dir() {
    echo $PWD

    if  [[ $(basename "$PWD") == "llvm-project" && -d $PWD/llvm ]]; then
        return
    fi

    # HACK: Go up and try again, once
    pushd $PWD/../

    if  [[ $(basename "$PWD") == "llvm-project" && -d $PWD/llvm ]]; then
        return
    fi

    err "[!] Run this script in the right directory"
    exit 1
}

prepare_and_switch_to_build_directory() {
    if [[  -d $PWD/$BUILD_DIR_BASENAME ]]; then
        if ! [[ -n $FORCE ]]; then
            err "[!] The build directory already exists"
            exit 1
        fi
        rm -rf $PWD/$BUILD_DIR_BASENAME
    fi

    mkdir $PWD/$BUILD_DIR_BASENAME
    pushd $PWD/$BUILD_DIR_BASENAME
    return
}

# Requires you are in the build directory
run_cmake() {
    cmake \
        -DLLVM_TARGETS_TO_BUILD="X86" \
        -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;clang-tools-extra;lld;libcxx;libcxxabi;libunwind" \
        -DCMAKE_BUILD_TYPE=Release \
        ../llvm
}

# NOTE: If you don't have enough memory. You will be in a trouble
run_make() {
    make "-j$1"
}

main() {
    while [ $# -gt 0 ]; do
        case $1 in
            -f|--force) { FORCE=1; };;
            -o|--optdir)
                if ! [[ $INSTALL_DIR == $home/opt ]]; then
                    break
                fi
                shift
                INSTALL_DIR=$1
                ;;
            -j|--jobs)
                shift
                JOBS_PARALLEL=$1
                ;;
            *)
                warn "[!] Unknown arguments"
        esac
        shift
    done

    echo "$FORCE | $INSTALL_DIR | $JOBS_PARALLEL"

    switch_to_llvm_dir

    prepare_and_switch_to_build_directory

    run_cmake

    run_make $JOBS_PARALLEL
}

main "$@"
