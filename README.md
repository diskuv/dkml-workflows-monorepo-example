# dkml-workflows-monorepo-example

An [Opam Monorepo](https://github.com/ocamllabs/opam-monorepo#readme) example for the
[dkml-workflow] GitHub Action workflows. DKML helps you
distribute native OCaml applications on the most common operating systems.
In particular [dkml-workflow] builds:
* Windows libraries and executables with the traditional Visual Studio compiler, avoiding hard-to-debug runtime issued caused by compiler incompatibilities
* macOS libraries and executables for both Intel and ARM64 (Apple Silicon) architectures
* Linux libraries and executables on an ancient "glibc" C library, letting you distribute your software to most Linux users
  while avoiding the alternative approach of [static linking the system C library](https://gavinhoward.com/2021/10/static-linking-considered-harmful-considered-harmful/)

[dkml-workflow]: https://github.com/diskuv/dkml-workflows#dkml-workflows

The full list of examples is:

| Example                                                                                      | Who For                                                                                                    |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [dkml-workflows-monorepo-example](https://github.com/diskuv/dkml-workflows-monorepo-example) | You want to cross-compile ARM64 on Mac Intel.<br>You are building [Mirage unikernels](https://mirage.io/). |
| [dkml-workflows-regular-example](https://github.com/diskuv/dkml-workflows-regular-example)   | Everybody else                                                                                             |

These workflows are **not quick** and won't improve unless you are willing to contribute PRs!
Expect to wait approximately:

| Build Step                                               | First Time | Subsequent Times |
| -------------------------------------------------------- | ---------- | ---------------- |
| setup-dkml / win32-windows_x86                           | `29m`      | `6m`             |
| setup-dkml / win32-windows_x86_64                        | `29m`      | `6m`             |
| setup-dkml / macos-darwin_all [1]                        | `29m`      | `6m`             |
| setup-dkml / manylinux2014-linux_x86 (CentOS 7, etc.)    | `16m`      | `5m`             |
| setup-dkml / manylinux2014-linux_x86_64 (CentOS 7, etc.) | `13m`      | `5m`             |
| build / win32-windows_x86                                | `23m`      | todo             |
| build / win32-windows_x86_64                             | `19m`      | todo             |
| build / macos-darwin_all                                 | `27m`      | todo             |
| build / manylinux2014-linux_x86 (CentOS 7, etc.)         | `09m`      | todo             |
| build / manylinux2014-linux_x86_64 (CentOS 7, etc.)      | `09m`      | todo             |
| release                                                  | `01m`      | todo             |
| **TOTAL** *(not cumulative since steps run in parallel)* | `57m`      | todo             |

You can see an example workflow at https://github.com/diskuv/dkml-workflows-monorepo-example/actions/workflows/package.yml

[1] `setup-dkml/macos-darwin_all` is doing double-duty: it is compiling x86_64 and arm64 systems.

## Differences from the Opam Regular build flow

* Opam Monorepo `pull` was used to pre-download all the Opam packages into the `duniverse/` directory
* The `dkml-base-compiler` and `conf-dkml-cross-toolchain` packages are used to get a cross-compiler for
  macOS.
* The [dune-universe](https://github.com/dune-universe/opam-overlays.git) Opam repository was added so
  that all Opam packages use Dune as their only build tool

## Outstanding Issues for Opam Monorepo

* Accept `dkml-base-compiler.4.12.1~v1.0.0` instead of just `ocaml-base-compiler.M.N.O`
* `conf-dkml-cross-toolchain` needs to be installed before any of the Dune packages are built; it
  provides the ocamlfind toolchains. Is this just `x-opam-monorepo-opam-provided`?

## Status

| What             | Branch/Tag | Status                                                                                                                                                                                                        |
| ---------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Builds and tests |            | [![Builds and tests](https://github.com/diskuv/dkml-workflows-monorepo-example/actions/workflows/build.yml/badge.svg)](https://github.com/diskuv/dkml-workflows-monorepo-example/actions/workflows/build.yml) |
| Static checks    |            | [![Static checks](https://github.com/diskuv/dkml-workflows-monorepo-example/actions/workflows/static.yml/badge.svg)](https://github.com/diskuv/dkml-workflows-monorepo-example/actions/workflows/static.yml)  |