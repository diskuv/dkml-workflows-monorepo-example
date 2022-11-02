#!/bin/sh
set -euf

teardown_WORKSPACE_VARNAME=$1
shift
teardown_WORKSPACE=$1
shift

# ------------------ Variables and functions ------------------------

# shellcheck source=./common-values.sh
. .ci/sd4/common-values.sh

# Fixup opam_root on Windows to be mixed case. Set original_* and unix_* as well.
fixup_opam_root

# Set TEMP variable for Windows
export_temp_for_windows

# -------------------------------------------------------------------

section_begin teardown-info "Summary: teardown-dkml"

# shellcheck disable=SC2154
echo "
================
teardown-dkml.sh
================
.
---------
Arguments
---------
WORKSPACE_VARNAME=$teardown_WORKSPACE_VARNAME
WORKSPACE=$teardown_WORKSPACE
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
opam_root=${opam_root}
opam_root_cacheable=${opam_root_cacheable}
original_opam_root=${original_opam_root}
original_opam_root_cacheable=${original_opam_root_cacheable}
unix_opam_root=${unix_opam_root}
unix_opam_root_cacheable=${unix_opam_root_cacheable}
.
"
section_end teardown-info

# Done with Opam cache!
do_save_opam_cache() {
    if [ "$unix_opam_root_cacheable" = "$unix_opam_root" ]; then return; fi
    section_begin save-opam-cache "Transfer Opam cache to $original_opam_root"
    echo Starting transfer # need some output or GitLab CI will not display the section duration
    transfer_dir "$unix_opam_root" "$unix_opam_root_cacheable"
    echo Finished transfer
    section_end save-opam-cache
}
do_save_opam_cache

do_fill_skipped_cache_entries() {
    section_begin fill-skipped-cache-entries "Populate skipped cache entries"

    # Needed to stop GitLab CI/CD cache warnings 'no matching files', etc.
    if [ ! -e .ci/sd4/vsenv.sh ]; then
        install -d .ci/sd4
        rm -f .ci/sd4/vsenv.sh
        touch .ci/sd4/vsenv.sh
        chmod +x .ci/sd4/vsenv.sh
        echo "Created empty vsenv.sh"
    else
        echo "Found vsenv.sh"
    fi

    if [ ! -e msys64 ]; then
        rm -rf msys64
        install -d msys64
        touch msys64/.keep
        echo "Created empty msys64"
    else
        echo "Found msys64/"
    fi

    if [ -s "$unix_opam_root_cacheable/.ci.dkml.repo-init" ]; then
        echo "Found non-empty $unix_opam_root_cacheable/.ci.dkml.repo-init"
    else
        touch "$unix_opam_root_cacheable/.ci.dkml.repo-init"
        echo "Created empty $unix_opam_root_cacheable/.ci.dkml.repo-init"
    fi

    if [ -s "$unix_opam_root_cacheable/.ci.two.repo-init" ]; then
        echo "Found non-empty $unix_opam_root_cacheable/.ci.two.repo-init"
    else
        touch "$unix_opam_root_cacheable/.ci.two.repo-init"
        echo "Created empty $unix_opam_root_cacheable/.ci.two.repo-init"
    fi

    section_end fill-skipped-cache-entries
}
do_fill_skipped_cache_entries

do_at_least_one_artifact() {
    install -d dist
    find dist -mindepth 1 -maxdepth 1 >.ci/dist.files
    if [ ! -s .ci/dist.files ]; then
        section_begin one-artifact "Create empty artifact file"

        # Avoid confusing "ERROR: No files to upload" in GitLab CI
        touch dist/.keep
        echo "Created dist/.keep"

        section_end one-artifact
    fi
}
do_at_least_one_artifact
