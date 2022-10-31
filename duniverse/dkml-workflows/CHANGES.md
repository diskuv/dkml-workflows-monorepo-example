## 1.1.0 (v1)

New Features:
- Desktop testing for macOS/Intel (or macOS/ARM64 with Rosetta emulator) and Linux 32/64-bit on Intel/AMD
- Help messages for desktop testing on Windows
- Optional secondary switch `two` in addition to primary switch `dkml` enabled with
  input variable `SECONDARY_SWITCH=true`

Breaking changes:
- The GitLab job names `build_linux`, `build_macos` and `build_win32` are now private job names `.linux:setup-dkml`,
  `.macos:setup-dkml` and `.win32:setup-dkml`. This means in your own `.gitlab-ci.yml` you will need an "extends" statement,
  like so:
  ```yaml
  build_linux:
    extends: .linux:setup-dkml # ADD THIS ONE LINE!
    script:
      - opamrun exec -- echo Build me some Linux stuff
  ```

  *Why break the API?*

  This change was done so you could do incremental staged builds where job A does only the setup (which caches the OCaml
  compiler) and where the second job B does both the setup and the full build of your OCaml code. By using a private job
  name that starts with a dot (.) like `.linux:setup-dkml`, both job A and job B can extend from `.**OS**:setup-dkml` to
  share the setting up of the OCaml compiler cache.

  The benefit you get for the extra complexity is that you are more likely to stay under GitLab runner
  time limits; the shared SaaS GitLab runners time out jobs at 2 hours.
  For example Job A can take one hour or more for Windows when you enable `SECONDARY_SWITCH=true`.

  Hypothetically you could do a full build of your code without the caching of the OCaml compiler that took 2.5 hours.
  GitLab would fail your full build with time limit failures. But by splitting job A from job B, job A takes 1-1.5 hours
  while job B would only take 1.5 hours plus a few minutes for reading the cache of job A. Now both job A and job B
  can work without running into time limits.

  *Why is it a minor break?*

  Since there was no announcement of the previous 1.0.0 version, it is unlikely anyone is broken. And if
  anyone is broken, they just need to add three `extends: .setup_dkml_XXX` to their script.

Other changes:
- Performance: Linux CI now avoids ~10 second ManyLinux (dockcross) unnecessary recursive chown of root:root
  owned container files. As long as calling user is root (which is true for GitHub Actions and GitLab CI/CD)
  the chown operation is skipped.
- Remove unused `gl_tags` matrix variable

## 1.0.0 (v1)

New Features:
1. Support GitLab CI/CD
2. Support desktop testing on Windows
3. GitHub now uses a composite action rather than a child
   workflow, resulting in less artifact copying and
   quicker builds.

There are significant breaking changes. It will be far easier
to onboard with [the new version `v1` instructions](https://github.com/diskuv/dkml-workflows/tree/v1#readme)
and then remove your `v0` code, rather than try to do an in-place upgrade:
* Any custom build logic you have in your GitHub workflow should go into
  the new `ci/build-test.sh`. Alternatively, if you don't care about ever running troubleshooting
  CI on your desktop or GitLab, directly into your new `.github/workflows/build-with-dkml.yml`.

Breaking changes:
- The GitHub child workflow has been replaced by a GitHub composite action
- Input variables have been renamed to allow the same variable names between GitHub Actions and
  GitLab CI/CD (the latter does not support dashes in variable names).

  | Old Name                  | New Name                  |
  | ------------------------- | ------------------------- |
  | cache-prefix              | CACHE_PREFIX              |
  | ocaml-compiler            | OCAML_COMPILER            |
  | dkml-compiler             | DKML_COMPILER             |
  | conf-dkml-cross-toolchain | CONF_DKML_CROSS_TOOLCHAIN |
  | diskuv-opam-repository    | DISKUV_OPAM_REPOSITORY    |
  | ocaml-options             | ocaml_options             |
  | vsstudio-arch             | vsstudio_arch             |
  | vsstudio-hostarch         | vsstudio_hostarch         |
  | vsstudio-dir              | vsstudio_dir              |
  | vsstudio-vcvarsver        | vsstudio_vcvarsver        |
  | vsstudio-winsdkver        | vsstudio_winsdkver        |
  | vsstudio-msvspreference   | vsstudio_msvspreference   |
  | vsstudio-cmakegenerator   | vsstudio_cmakegenerator   |

- Matrix variables have been renamed to allow the same variable names between GitHub Actions and
  GitLab CI/CD (the latter does not support dashes in variable names).

- The shell matrix variable `default_shell` has been renamed `gh_unix_shell`

- The operating system matrix variable has been reorganized to distingush GitHub
  from GitLab:

  - `os` is now `gh_os` and in use only for GitHub Actions
  - `gl_tags` and `gl_image` are the new GitLab CI/CD equivalents. GitLab CI/CD uses tags like
    `[shared-windows, windows, windows-1809]` to specify the type of runner machine to use,
    and for macOS image you can supply an XCode version like `macos-11-xcode-12`.

## v0

Initial release