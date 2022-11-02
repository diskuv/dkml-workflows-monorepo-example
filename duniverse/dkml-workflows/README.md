# dkml-workflows

GitLab CI/CD, GitHub Actions and desktop scripts to setup Diskuv OCaml
(DKML) compilers. DKML helps you distribute native OCaml applications on the
most common operating systems.

Table of Contents:
- [dkml-workflows](#dkml-workflows)
  - [Configure your project](#configure-your-project)
  - [Create `ci/build-test.sh`](#create-cibuild-testsh)
  - [Examples](#examples)
  - [Using the GitLab CI/CD backend](#using-the-gitlab-cicd-backend)
  - [Using the GitHub Actions backend](#using-the-github-actions-backend)
  - [Using the Personal Computer backend](#using-the-personal-computer-backend)
    - [Windows PC backend](#windows-pc-backend)
    - [macOS and Linux backends](#macos-and-linux-backends)
  - [Distributing your executable](#distributing-your-executable)
    - [Distributing your Windows executables](#distributing-your-windows-executables)
  - [Advanced Usage](#advanced-usage)
    - [Job Inputs](#job-inputs)
      - [SECONDARY_SWITCH](#secondary_switch)
      - [CACHE_PREFIX](#cache_prefix)
      - [FDOPEN_OPAMEXE_BOOTSTRAP](#fdopen_opamexe_bootstrap)
    - [Matrix Variables](#matrix-variables)
      - [gl_image](#gl_image)
      - [gh_os](#gh_os)
      - [bootstrap_opam_version](#bootstrap_opam_version)
      - [opam_root](#opam_root)
      - [vsstudio_hostarch](#vsstudio_hostarch)
      - [vsstudio_arch](#vsstudio_arch)
      - [vsstudio_(others)](#vsstudio_others)
      - [ocaml_options:](#ocaml_options)
  - [Sponsor](#sponsor)

This project gives you "`setup-dkml`" scripts to build and automatically create
releases of OCaml native executables.

In contrast to the conventional [setup-ocaml](https://github.com/marketplace/actions/set-up-ocaml) GitHub Action:

| `setup-dkml`                         | `setup-ocaml`             | Consequence                                                                                                                                                                                                                                                                                                 |
| ------------------------------------ | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| dkml-base-compiler                   | ocaml-base-compiler       | `setup-dkml` **only supports 4.12.1 today**. `setup-ocaml` supports all versions and variants of OCaml                                                                                                                                                                                                      |
| GitHub Local Action                  | GitHub Marketplace Action | `setup-dkml` uses Dune and Opam to distribute the GitHub build logic, while `setup-ocaml` is distributed through GitHub Marketplace which is easier to use                                                                                                                                                  |
| GitLab CI/CD Local Include           | *not supported*           | `setup-dkml` supports GitLab CI/CD                                                                                                                                                                                                                                                                          |
| Personal Computer Scripts            | *not supported*           | `setup-dkml` can generates scripts (only Windows today) to simulate CI on your personal computer for troubleshooting                                                                                                                                                                                        |
| MSVC + MSYS2                         | GCC + Cygwin              | On Windows `setup-dkml` can let your native code use ordinary Windows libraries without ABI conflicts. You can also distribute your executables without the license headache of redistributing or statically linking `libgcc_s_seh` and `libstdc++`                                                         |
| dkml-base-compiler                   | ocaml-base-compiler       | On macOS, `setup-dkml` cross-compiles to ARM64 with `dune -x darwin_arm64`                                                                                                                                                                                                                                  |
| CentOS 7 and Linux distros from 2014 | Latest Ubuntu             | On Linux, `setup-dkml` builds with an old GLIBC. `setup-dkml` dynamically linked Linux executables will be highly portable as GLIBC compatibility issues should be rare, and compatible with the unmodified LGPL license used by common OCaml dependencies like [GNU MP](https://gmplib.org/manual/Copying) |
| 0 yrs                                | 4 yrs                     | `setup-ocaml` is officially supported and well-tested.                                                                                                                                                                                                                                                      |
| Some pinned packages                 | No packages pinned        | `setup-dkml`, for some packages, must pin the version so that cross-platform patches (especially for Windows) are available. With `setup-ocaml` you are free to use any version of any package                                                                                                              |
| diskuv/diskuv-opam-repository        | fdopen/opam-repository    | Custom patches for Windows are sometimes needed. `setup-dkml` uses a much smaller set of patches. `setup-ocaml` uses a large but deprecated set of patches.                                                                                                                                                 |

> Put simply, use `setup-dkml` when you are distributing executables or libraries to the public. Use `setup-ocaml` for all other needs.

`setup-dkml` will setup the following OCaml build environments for you:

| ABIs                         | Native `ocamlopt` compiler supports building executables for the following operating systems:                                            |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `win32-windows_x86`          | 32-bit Windows [1] for Intel/AMD CPUs                                                                                                    |
| `win32-windows_x86_64`       | 64-bit Windows [1] for Intel/AMD CPUs                                                                                                    |
| `macos-darwin_all`           | 64-bit macOS for Intel and Apple Silicon CPUs. Using `dune -x darwin_arm64` will cross-compile [2] to both; otherwise defaults to Intel. |
| `manylinux2014-linux_x86`    | 32-bit Linux: CentOS 7, CentOS 8, Fedora 32+, Mageia 8+, openSUSE 15.3+, Photon OS 4.0+ (3.0+ with updates), Ubuntu 20.04+               |
| `manylinux2014-linux_x86_64` | 64-bit Linux: CentOS 7, CentOS 8, Fedora 32+, Mageia 8+, openSUSE 15.3+, Photon OS 4.0+ (3.0+ with updates), Ubuntu 20.04+               |

> **[1]** See [Distributing your Windows executables](#distributing-your-windows-executables) for further details

> **[2]** Cross-compiling typically requires that you use Dune to build all your OCaml package dependencies.
> [opam monorepo](https://github.com/ocamllabs/opam-monorepo#readme) makes it easy to do exactly that.
> Alternatively you can directly use [findlib toolchains](http://projects.camlcity.org/projects/dl/findlib-1.9.3/doc/ref-html/r865.html).

You can follow the sections on this page, or you can copy one of the examples:

| Example                                                                                      | Who For                                                                                                                                         |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| [dkml-workflows-monorepo-example](https://github.com/diskuv/dkml-workflows-monorepo-example) | **Not ready for public use yet!**<br>You want to cross-compile ARM64 on Mac Intel.<br>You are building [Mirage unikernels](https://mirage.io/). |
| [dkml-workflows-regular-example](https://github.com/diskuv/dkml-workflows-regular-example)   | Everybody else                                                                                                                                  |

For news about Diskuv OCaml,
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/diskuv.svg?style=social&label=Follow%20%40diskuv)](https://twitter.com/diskuv) on Twitter.

## Configure your project

FIRST, add a dependency to `dkml-workflows` in your project.

- For projects using `dune-project`:
  1. Add the following to `dune-project`:
     ```scheme
     (package
       ; ...
       (dkml-workflows (and (>= 1.1.0) :build))
       ...
     )
     ```
  2. Then do `dune build *.opam`
- For projects not using `dune-project`:
  1. Add the following to your `<project>.opam`:
     ```
     # ...
     depends: [
       "ocaml"
       "dune" {>= "2.9"}
       "dkml-workflows" {>= "1.1.0" & build}
     ]
     # ...
     ```

SECOND, update your Opam switch with the new `dkml-workflows` dependency:

```
git commit -a -m 'Add dkml-workflows@v1'
opam install . --deps-only
```

THIRD, create or edit your `.gitattributes` in your project root directory
so that Windows scripts are encoded correctly. `.gitattributes` should contain
at least the following:

```properties
# Set the default behavior, in case people don't have core.autocrlf set.
# This is critical for Windows and UNIX interoperability.
* text=auto

# Declare files that will always have LF line endings on checkout.
.gitattributes text eol=lf

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.1
# > Creating PowerShell scripts on a Unix-like platform or using a cross-platform editor on Windows, such as Visual Studio Code,
# >   results in a file encoded using UTF8NoBOM. These files work fine on PowerShell Core, but may break in Windows PowerShell if
# >   the file contains non-Ascii characters.
# > In general, Windows PowerShell uses the Unicode UTF-16LE encoding by default.
# > Using any Unicode encoding, except UTF7, always creates a BOM.
#
# Hint: If a file is causing you problems (ex. `fatal: BOM is required in ... if encoded as UTF-16`) use
#       "View > Change File Encoding > Save with Encoding > UTF-16LE" in Visual Studio Code to save the file correctly.
*.ps1 text working-tree-encoding=UTF-16 eol=crlf
```

FOURTH, generate scaffolding files:

```
opam exec -- generate-setup-dkml-scaffold
opam exec -- dune build '@gen-dkml' --auto-promote
```

FIFTH, add the scaffolding files to your source control. Assuming you use git, it would be:

```
git add ci/setup-dkml
```

## Create `ci/build-test.sh`

Your build logic will be inside a POSIX shell script. This will work even on Windows; just be careful on Windows
that you save the shell script with LF line endings (not CRLF), and use UTF-8 encoding.

You don't need to name the file `ci/build-test.sh` however the
documentation assumes that filename.

At minimum the file should contain:

```bash
#!/bin/sh
set -euf

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# PATH. Add opamrun
export PATH="$PROJECT_DIR/.ci/sd4/opamrun:$PATH"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun option
opamrun exec -- ocamlc -config

# Update
opamrun update

# Make your own build logic! It may look like ...
opamrun install . --deps-only --with-test
opamrun exec -- dune runtest
```

## Examples

The full list of examples is:

| Example                                                                                      | Who For                                                                                                                                         |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| [dkml-workflows-monorepo-example](https://github.com/diskuv/dkml-workflows-monorepo-example) | **Not ready for public use yet!**<br>You want to cross-compile ARM64 on Mac Intel.<br>You are building [Mirage unikernels](https://mirage.io/). |
| [dkml-workflows-regular-example](https://github.com/diskuv/dkml-workflows-regular-example)   | Everybody else                                                                                                                                  |

## Using the GitLab CI/CD backend

> macOS runners are not available in the GitLab CI/CD shared fleet unless
> you apply and are approved at
> https://gitlab.com/gitlab-com/runner-saas-macos-access-requests/-/issues/new . More details are
> available at https://gitlab.com/gitlab-com/runner-saas-macos-access-requests/-/blob/main/README.md
>
> This documentation assumes you have not been approved. There will be callouts
> for where to edit once you have been approved for macOS.

Create a `.gitlab-ci.yml` in the project root directory that contains
at least:

```yaml
include:
  - local: 'ci/setup-dkml/gl/setup-dkml.gitlab-ci.yml'

linux:build:
  extends: .linux:setup-dkml
  script:
    - sh ci/build-test.sh

win32:build:
  extends: .win32:setup-dkml
  script:
    - msys64\usr\bin\bash -lc "ci/build-test.sh"

# Uncomment macOS when you have a https://gitlab.com/gitlab-com/runner-saas-macos-access-requests/-/issues
# approved!
#
# macos:build:
#   extends: .macos:setup-dkml
#   script:
#     - sh ci/build-test.sh --opam-package "$THE_OPAM_PACKAGE" --executable-name "$THE_EXECUTABLE_NAME"
```

The [Examples](#examples) include more features, like the uploading and releasing of your built artifacts.

## Using the GitHub Actions backend

Create a GitHub workflow file in `.github/workflows` that contains at least:

```yaml
# Suggested filename: .github/workflows/build-with-dkml.yml

name: Build with DKML compiler

env:
  OPAM_PACKAGE: "your_example"
  EXECUTABLE_NAME: "your_example"
  DKML_COMPILER: "" # You can override the dkml-compiler package version. Example: 4.12.1-v1.0.2

on:
  push:
    branches:
      - main
      - v*
    tags:
      - v*
  # ... or trigger manually from GitHub web interface
  workflow_dispatch:

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - gh_os: windows-2019
            abi_pattern: win32-windows_x86
            dkml_host_abi: windows_x86
          - gh_os: windows-2019
            abi_pattern: win32-windows_x86_64
            dkml_host_abi: windows_x86_64
          - gh_os: ubuntu-latest
            abi_pattern: manylinux2014-linux_x86
            dkml_host_abi: linux_x86
          - gh_os: ubuntu-latest
            abi_pattern: manylinux2014-linux_x86_64
            dkml_host_abi: linux_x86_64
          - gh_os: macos-latest
            abi_pattern: macos-darwin_all
            dkml_host_abi: darwin_x86_64

    runs-on: ${{ matrix.gh_os }}
    name: build / ${{ matrix.abi_pattern }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      # The Setup DKML action will create the environment variables:
      #   opam_root, exe_ext, dkml_host_abi, abi_pattern (and many more)

      - name: Setup DKML on a Windows host
        if: startsWith(matrix.dkml_host_abi, 'windows_')
        uses: ./ci/setup-dkml/gh-windows/pre
        with:
          DKML_COMPILER: ${{ env.DKML_COMPILER }}

      - name: Setup DKML on a Darwin host
        if: startsWith(matrix.dkml_host_abi, 'darwin_')
        uses: ./ci/setup-dkml/gh-darwin/pre
        with:
          DKML_COMPILER: ${{ env.DKML_COMPILER }}

      - name: Setup DKML on a Linux host
        if: startsWith(matrix.dkml_host_abi, 'linux_')
        uses: ./ci/setup-dkml/gh-linux/pre
        with:
          DKML_COMPILER: ${{ env.DKML_COMPILER }}

      # This section is for your own build logic which you should place in ci/build-test.sh or a similar file

      - name: Build and test the package on Windows host
        if: startsWith(matrix.dkml_host_abi, 'windows_')
        shell: msys2 {0}
        run: ci/build-test.sh --opam-package ${{ env.OPAM_PACKAGE }} --executable-name ${{ env.EXECUTABLE_NAME }}

      - name: Build and test the package on non-Windows host
        if: "!startsWith(matrix.dkml_host_abi, 'windows_')"
        run: ci/build-test.sh --opam-package ${{ env.OPAM_PACKAGE }} --executable-name ${{ env.EXECUTABLE_NAME }}

      # The Teardown DKML action will finalize caching, etc.

      - name: Teardown DKML on a Windows host
        if: startsWith(matrix.dkml_host_abi, 'windows_')
        uses: ./ci/setup-dkml/gh-windows/post

      - name: Teardown DKML on a Darwin host
        if: startsWith(matrix.dkml_host_abi, 'darwin_')
        uses: ./ci/setup-dkml/gh-darwin/post

      - name: Teardown DKML on a Linux host
        if: startsWith(matrix.dkml_host_abi, 'linux_')
        uses: ./ci/setup-dkml/gh-linux/post
```

The [Examples](#examples) include more features, like the uploading and releasing of your built artifacts.

## Using the Personal Computer backend

This backend is meant for troubleshooting when a GitLab CI/CD or GitHub Actions
backend fails to build your code. You can do the build locally!

> Currently this backend only runs on:
> 1. Windows PCs with Visual Studio already installed
> 2. macOS/Intel with clang (XCode) already installed. macOS/ARM64 with Rosetta emulation
>    should also work.

### Windows PC backend

On Windows in PowerShell run:

```powershell
& ci\setup-dkml\pc\setup-dkml-windows_x86_64.ps1
```

You can use `& ci\setup-dkml\pc\setup-dkml-windows_x86.ps1` for 32-bit Windows
builds.

After running the `.ps1` script you will see instructions for running
Opam commands in your PowerShell terminal.

To see all of the advanced options that can be set, use:

```powershell
get-help ci\setup-dkml\pc\setup-dkml-windows_x86_64.ps1 -Full
```

See [Advanced Usage: Job Inputs](#job-inputs) for some of the advanced options that
can be set.

### macOS and Linux backends

Run one of:

```bash
# macOS/Intel (or macOS/ARM64 with Rosetta emulator)
sh ci/setup-dkml/pc/setup-dkml-darwin_x86_64.sh

# Linux on 64-bit Intel/AMD
sh ci/setup-dkml/pc/setup-dkml-linux_x86_64.sh

# Linux on 32-bit Intel/AMD
sh ci/setup-dkml/pc/setup-dkml-linux_x86.sh
```

To see all of the advanced options that can be set, use:

```powershell
sh ci/setup-dkml/pc/setup-dkml-darwin_x86_64.sh -h
```

See [Advanced Usage: Job Inputs](#job-inputs) for some of the advanced options that
can be set.

## Distributing your executable

### Distributing your Windows executables

Since your executable has been compiled with the Microsoft Visual Studio
Compiler (MSVC), your executable will require that the Visual Studio
Runtime (`vcruntime140.dll`) is available on your end-user's machine.

If your end-user recently purchased a Windows machine the Visual C++ Redistributable
will not be present; they would see the following if they tried to run your
executable:

![vcruntime140.dll is missing](images/vcruntime140_missing.png)

`vcruntime140.dll` and other DLLs that are linked into your executable
by Visual Studio are available as part of the
[Visual C++ Redistributable Packages](https://docs.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files).

As of April 2022 the Redistributable Packages only support Windows Vista, 7,
8.1, 10, and 11. Windows XP is **not** supported.

To get the Redistributable Packages onto your end-user's
machine, do one of the following:

1. Ask your end-user to download from one of the links on (Microsoft Visual C++ Redistributable latest supported downloads)[https://docs.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist]. The end-user will need Administrator privileges.
2. Bundle your executable inside a standard Windows installer (NSIS, Wix, etc.). You can see NSIS instructions below. The end-user will need Administrator privileges.
3. Ask your user to download `vcruntime140.dll` and place it in the same
   directory as your executable. This is not recommended because Windows Update
   will not be able to apply any security updates to your locally deployed
   `vcruntime140.dll`.

---

If you choose option 2 and are using NSIS as your Windows installer, you can add
the following NSIS section to your NSIS configuration:

```nsis
Section "Visual C++ Redistributable Packages"
  SetOutPath "$INSTDIR"
  !include "x64.nsh"
  ${If} ${IsNativeAMD64}
    File "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Redist\MSVC\14.29.30133\vc_redist.x64.exe"
    ExecWait '"$INSTDIR\vc_redist.x64.exe" /install /passive'
    Delete "$INSTDIR\vc_redist.x64.exe"
  ${ElseIf} ${IsNativeARM64}
    File "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Redist\MSVC\14.29.30133\vc_redist.arm64.exe"
    ExecWait '"$INSTDIR\vc_redist.arm64.exe" /install /passive'
    Delete "$INSTDIR\vc_redist.arm64.exe"
  ${ElseIf} ${IsNativeIA32}
    File "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Redist\MSVC\14.29.30133\vc_redist.x86.exe"
    ExecWait '"$INSTDIR\vc_redist.x86.exe" /install /passive'
    Delete "$INSTDIR\vc_redist.x86.exe"
  ${Else}
    Abort "Unsupported CPU architecture!"
  ${EndIf}
SectionEnd
```

When you run the `makensis.exe` NSIS compiler the specified `File` must be
present on the `makensis.exe` machine. Make sure you have set it correctly!
If the NSIS compiler is running
as part of the GitHub Actions, you can
look at the output of setup-dkml.yml's step
"Capture Visual Studio compiler environment (2/2)"; the directory will be
the `VCToolsRedistDir` environment variable. The `VCToolsRedistDir` environment
variable will also be available to use as
`opamrun exec -- sh -c 'echo $VCToolsRedistDir'`

## Advanced Usage

### Job Inputs

#### SECONDARY_SWITCH

When set to `true` the scripts will CI jobs will create the `two` switch in addition to the always present `dkml` switch.

When using the secondary switch, be sure to use `--switch dkml` or `--switch two` in _all_ of your `opamrun` commands.

For example, use `opamrun install --switch dkml dune` rather than `opamrun install dune`.

#### CACHE_PREFIX

The prefix of the cache keys.

#### FDOPEN_OPAMEXE_BOOTSTRAP

Boolean. Either `true` or anything else (ex. `false`).

Use opam.exe from fdopen on Windows. Typically only used when bootstrapping Opam for the first time. May be needed to solve '\"create_process\" failed on sleep: Bad file descriptor' which may need https://github.com/ocaml/opam/commit/417b97d8cfada35682a0f4107eb2e4f9e24fba91

### Matrix Variables

#### gl_image

The GitLab virtual machine image for macOS. Examples: `macos-11-xcode-12`.

Linux always uses a [Docker-in-Docker image](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-in-docker).

#### gh_os

The GitHub Actions operating system.

#### bootstrap_opam_version

We need an old working Opam; see BOOTSTRAPPING.md of dkml-installer repository.
We use https://github.com/diskuv/dkml-installer-ocaml/releases
to get an old one; you specify its version number here.

Special value of 'os' means use the OS's package manager
(yum/apt/brew).

#### opam_root

OPAMROOT must be a subdirectory of GITHUB_WORKSPACE if running in
dockcross so that the Opam root (and switch) is visible in both the
parent and Docker context. Always specify this form as a relative
path under GITHUB_WORKSPACE.

When not using dockcross, it should be an absolute path to a
directory with a short length to minimize the 260 character
limit on Windows (macOS/XCode also has some small limit).

CAUTION: The opam_root MUST be in sync with outputs.import_func!

#### vsstudio_hostarch

Only needed if `gh_os: windows-*`. The ARCH in
`vsdevcmd.bat -host_arch=ARCH`. Example: x64.

If you have a 64-bit Intel machine you should not use x86 because
_WIN64 will be defined (see https://docs.microsoft.com/en-us/cpp/preprocessor/predefined-macros?view=msvc-170)
which is based on the host machine architecture (unless you explicitly
cross-compile with different ARCHs; that is, -host_arch=x64 -arch=x75).
Confer: https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170#use-the-developer-tools-in-an-existing-command-window

If you see ppx problems with missing _BitScanForward64 then
https://github.com/janestreet/base/blob/8993e35ba2e83e5020b2deb548253ef1e4a699d4/src/int_math_stubs.c#L25-L32
has been compiled with the wrong host architecture.

#### vsstudio_arch

Only needed if `gh_os: windows-*`. The ARCH in
`vsdevcmd.bat -arch=ARCH`. Example: x86.
Confer: https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170#use-the-developer-tools-in-an-existing-command-window

#### vsstudio_(others)

Hardcodes details about Visual Studio rather than let DKML discover
a compatible Visual Studio installation.

Example:

    vsstudio_dir: 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'
    vsstudio_vcvarsver: '14.16'
    vsstudio_winsdkver: '10.0.18362.0'
    vsstudio_msvspreference: 'VS16.5'
    vsstudio_cmakegenerator: 'Visual Studio 16 2019'

#### ocaml_options:

Space separated list of `ocaml-option-*` packages.

Use 32-bit installers when possible for maximum portability of
OCaml bytecode. Linux has difficulty with 32-bit (needs gcc-multilib, etc.)
macos is only the major platform without 32-bit.

You don't need to include `ocaml-option-32bit` because it is auto
chosen when the target ABI ends with x86.

## Sponsor

<a href="https://ocaml-sf.org">
<img align="left" alt="OCSF logo" src="https://ocaml-sf.org/assets/ocsf_logo.svg"/>
</a>
Thanks to the <a href="https://ocaml-sf.org">OCaml Software Foundation</a>
for economic support to the development of Diskuv OCaml.
<p/>
