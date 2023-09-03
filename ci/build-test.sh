#!/bin/sh
# -----------------------------------
# Compile and cross-compile with Dune
# -----------------------------------

set -euf

OPAM_PACKAGE=your_example.opam
EXECUTABLE_NAME=your_example

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

OPAM_PKGNAME=${OPAM_PACKAGE%.opam}

# Prereqs for Dune building including cross-compiling with ocamlfind toolchains
opamrun install dune ocamlfind --yes

# Build and test on the host ABI. Don't do cross-compiled testing since can't run
# cross-compiled binaries unless we have emulators
opamrun exec -- dune build -p "${OPAM_PKGNAME}" --promote-install-files=false @install @runtest

# Cross-compile to one or more target ABI if the host ABI and DKML support it
case "${dkml_host_abi}" in
darwin_*)
  opamrun exec -- dune build -p "${OPAM_PKGNAME}" -x darwin_arm64 --promote-install-files=false @install
  ;;
esac

# Prepare Diagnostics
case "${dkml_host_abi}" in
linux_*)
    if command -v apk; then
        apk add file
    fi ;;
esac

# Copy the installed binaries (including cross-compiled ones) from Opam into dist/ folder.
#
# dist/
#   <dkml_target_abi>/
#      <file1>
#      ...
install -d dist/
EXENAME=${EXECUTABLE_NAME%.exe}
mv _build/install/default "_build/install/default.${dkml_host_abi}"
set +f
for i in _build/install/default.*; do
  dkml_target_abi=$(basename "$i" | sed s/default.//)
  # Copy executable
  install -d "dist/${dkml_target_abi}"
  if [ -e "_build/install/default.${dkml_target_abi}/bin/${EXENAME}.exe" ]; then
    install -v "_build/install/default.${dkml_target_abi}/bin/${EXENAME}.exe" "dist/${dkml_target_abi}/${EXENAME}.exe"
    file "dist/${dkml_target_abi}/${EXENAME}.exe"
  else
    install -v "_build/install/default.${dkml_target_abi}/bin/${EXENAME}" "dist/${dkml_target_abi}/${EXENAME}"
    file "dist/${dkml_target_abi}/${EXENAME}"
  fi
  # For Windows you must ask your users to first install the vc_redist executable.
  # Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
  case "${dkml_target_abi}" in
  windows_x86_64) wget -O "dist/${dkml_target_abi}/vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
  windows_x86) wget -O "dist/${dkml_target_abi}/vc_redist.x86.exe" https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
  windows_arm64) wget -O "dist/${dkml_target_abi}/vc_redist.arm64.exe" https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
  esac
done
set -f
