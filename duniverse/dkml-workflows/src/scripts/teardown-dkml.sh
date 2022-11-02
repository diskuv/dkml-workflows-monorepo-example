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
    section_begin save-opam-cache "Transferring Opam cache to $original_opam_root"
    echo Starting transfer # need some output or GitLab CI will not display the section duration
    transfer_dir "$unix_opam_root" "$unix_opam_root_cacheable"
    echo Finished transfer
    section_end save-opam-cache
}
do_save_opam_cache
