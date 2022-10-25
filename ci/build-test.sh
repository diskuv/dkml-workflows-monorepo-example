#!/bin/sh
# -----------------------------------
# Compile and cross-compile with Dune
# -----------------------------------

set -euf

usage() {
  echo "'--opam-package OPAM_PACKAGE.opam --executable-name EXECUTABLE_NAME' where you have a (executable (public_name EXECUTABLE_NAME) ...) in some 'dune' file" >&2
  exit 3
}
OPTION=$1
shift
[ "$OPTION" = "--opam-package" ] || usage
OPAM_PACKAGE=$1
shift
OPTION=$1
shift
[ "$OPTION" = "--executable-name" ] || usage
EXECUTABLE_NAME=$1
shift

# If (executable (public_name EXECUTABLE_NAME) ...) already has .exe then executable will
# have .exe. Otherwise it depends on exe_ext.
case "$EXECUTABLE_NAME" in
*.exe) suffix_ext="" ;;
*) suffix_ext="${exe_ext:-}" ;;
esac

# shellcheck disable=SC2154
echo "
======================
build-test.sh
======================
.
---------
Arguments
---------
OPAM_PACKAGE=$OPAM_PACKAGE
EXECUTABLE_NAME=$EXECUTABLE_NAME
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
-------
Derived
-------
suffix_ext=$suffix_ext
.
"

# PATH. Add opamrun
if [ -n "${CI_PROJECT_DIR:-}" ]; then
  export PATH="$CI_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
  export PATH="$PC_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
  export PATH="$GITHUB_WORKSPACE/.ci/sd4/opamrun:$PATH"
else
  export PATH="$PWD/.ci/sd4/opamrun:$PATH"
fi

# Initial Diagnostics
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun exec -- ocamlc -config
xswitch=$(opamrun var switch)
if [ -x /usr/bin/cypgath ]; then
  xswitch=$(/usr/bin/cygpath -au "$xswitch")
fi
if [ -e "$xswitch/src-ocaml/config.log" ]; then
  echo '--- BEGIN src-ocaml/config.log ---' >&2
  cat "$xswitch/src-ocaml/config.log" >&2
  echo '--- END src-ocaml/config.log ---' >&2
fi

# -----------------------------------

# Prereqs for Dune building including cross-compiling with ocamlfind toolchains
opamrun install dune ocamlfind --yes

# Build and test on the host ABI. Don't do cross-compiled testing since can't run
# cross-compiled binaries unless we have emulators
opamrun exec -- dune build
opamrun exec -- dune runtest

# Cross-compile to one or more target ABI if the host ABI and DKML support it
case "${dkml_host_abi}" in
darwin_*)
  opamrun exec -- dune build -x darwin_arm64
  ;;
esac

# Copy the installed binaries (including cross-compiled ones) from Opam into dist/ folder.
# Name the binaries with the target ABI since GitHub Releases are flat namespaces.
install -d dist/
mv _build/install/default "_build/install/default.${dkml_host_abi}"
set +f
for i in _build/install/default.*; do
  target_abi=$(basename "$i" | sed s/default.//)
  if [ -e "_build/install/default.${target_abi}/bin/${OPAM_PACKAGE}.exe" ]; then
    install -v "_build/install/default.${target_abi}/bin/${OPAM_PACKAGE}.exe" "dist/${target_abi}-${OPAM_PACKAGE}.exe"
  else
    install -v "_build/install/default.${target_abi}/bin/${OPAM_PACKAGE}" "dist/${target_abi}-${OPAM_PACKAGE}"
  fi
done

# For Windows you must ask your users to first install the vc_redist executable.
# Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
case "${dkml_host_abi}" in
windows_x86_64) wget -O dist/vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
windows_x86) wget -O dist/vc_redist.x86.exe https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
windows_arm64) wget -O dist/vc_redist.arm64.exe https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
esac
