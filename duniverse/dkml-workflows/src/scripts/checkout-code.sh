#!/bin/sh

# ================
# checkout-code.sh
# ================
#
# Checkouts all of the git source code.
#
# This should be done outside of
# dockcross (used by Linux) since a Docker-in-Docker container can have
# difficulties doing a git checkout (the Git credentials for any private
# repositories are likely not present). We don't care about any private
# repositories for DKML but any code that extends this (ex. DKSDK) may
# need to use private repositories.

set -euf

setup_WORKSPACE_VARNAME=$1
shift
setup_WORKSPACE=$1
shift

# ------------------------ Functions ------------------------

# shellcheck source=./common-values.sh
. .ci/sd4/common-values.sh

# Disable automatic garbage collection
git_disable_gc() {
    git_disable_gc_NAME=$1
    shift
    git -C ".ci/sd4/g/$git_disable_gc_NAME" config --local gc.auto 0
}

# Mimic the behavior of GitHub's actions/checkout@v3
# - the plus symbol in 'git fetch ... origin +REF:refs/tags/v0.0' overrides any existing REF
git_checkout() {
    git_checkout_NAME=$1
    shift
    git_checkout_URL=$1
    shift
    git_checkout_REF=$1
    shift

    if [ -e ".ci/sd4/g/$git_checkout_NAME" ]; then
        git_disable_gc "$git_checkout_NAME"
        git -C ".ci/sd4/g/$git_checkout_NAME" remote set-url origin "$git_checkout_URL"
        git -C ".ci/sd4/g/$git_checkout_NAME" fetch --no-tags --progress --no-recurse-submodules --depth=1 origin "+${git_checkout_REF}:refs/tags/v0.0"
    else
        install -d ".ci/sd4/g/$git_checkout_NAME"
        git -C ".ci/sd4/g/$git_checkout_NAME" -c init.defaultBranch=main init
        git_disable_gc "$git_checkout_NAME"
        git -C ".ci/sd4/g/$git_checkout_NAME" remote add origin "$git_checkout_URL"
        git -C ".ci/sd4/g/$git_checkout_NAME" fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin "+${git_checkout_REF}:refs/tags/v0.0"
    fi
    git -C ".ci/sd4/g/$git_checkout_NAME" -c advice.detachedHead=false checkout --progress --force refs/tags/v0.0
    git -C ".ci/sd4/g/$git_checkout_NAME" log -1 --format='%H'
}

# ---------------------------------------------------------------------

section_begin checkout-info "Summary: code checkout"

# shellcheck disable=SC2154
echo "
================
checkout-code.sh
================
.
---------
Arguments
---------
WORKSPACE_VARNAME=$setup_WORKSPACE_VARNAME
WORKSPACE=$setup_WORKSPACE
.
------
Inputs
------
VERBOSE=${VERBOSE:-}
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
.
"

section_end checkout-info

install -d .ci/sd4/g

# dkml-runtime-distribution

case "$dkml_host_abi" in
windows_*)
    section_begin checkout-dkml-runtime-distribution 'Checkout dkml-runtime-distribution'
    git_checkout dkml-runtime-distribution https://github.com/diskuv/dkml-runtime-distribution.git "1a3ec82dd851751a95e6a4797387a8163c51520e"
    section_end checkout-dkml-runtime-distribution
    ;;
esac
