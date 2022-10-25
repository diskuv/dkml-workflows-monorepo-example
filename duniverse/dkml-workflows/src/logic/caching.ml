open Astring
open Jingoo

(* GitLab CI/CD constraints: https://docs.gitlab.com/ee/ci/yaml/index.html#cachekey *)

let cachebust = 1

let cachekey_opambin ~read_script ~input ~matrix =
  match read_script "setup-dkml.sh" with
  | None -> failwith "The script setup-dkml.sh was not found"
  | Some script ->
      [
        string_of_int cachebust;
        (* The DEFAULT_DISKUV_OPAM_REPOSITORY_TAG is inside setup-dkml.sh. We just take the
           md5 of it so we implicitly have a dependency on DEFAULT_DISKUV_OPAM_REPOSITORY_TAG *)
        Digest.string script |> Digest.to_hex |> String.with_range ~len:6;
        input "FDOPEN_OPAMEXE_BOOTSTRAP";
        matrix "dkml_host_abi";
        matrix "opam_abi";
        matrix "bootstrap_opam_version";
      ]

let cachekey_vsstudio ~input:_ ~matrix =
  [
    string_of_int cachebust;
    matrix "abi_pattern";
    matrix "vsstudio_arch";
    matrix "vsstudio_hostarch";
    matrix "vsstudio_dir";
    matrix "vsstudio_vcvarsver";
    matrix "vsstudio_winsdkver";
    matrix "vsstudio_msvspreference";
    matrix "vsstudio_cmakegenerator";
  ]

let cachekey_ci_inputs ~input ~matrix:_ =
  [
    string_of_int cachebust;
    input "OCAML_COMPILER";
    input "DISKUV_OPAM_REPOSITORY";
    input "DKML_COMPILER";
    input "CONF_DKML_CROSS_TOOLCHAIN";
  ]

let gh_cachekeys read_script =
  let join = String.concat ~sep:"-" in
  let input s = Printf.sprintf "${{ inputs.%s }}" s in
  let matrix s = Printf.sprintf "${{ steps.full_matrix_vars.outputs.%s }}" s in
  [
    ( "gh_cachekey_opambin",
      Jg_types.Tstr (join (cachekey_opambin ~read_script ~input ~matrix)) );
    ( "gh_cachekey_ci_inputs",
      Jg_types.Tstr (join (cachekey_ci_inputs ~input ~matrix)) );
    ( "gh_cachekey_vsstudio",
      Jg_types.Tstr (join (cachekey_vsstudio ~input ~matrix)) );
  ]

let gl_cachekeys read_script =
  let join = String.concat ~sep:"-" in
  let input s = Printf.sprintf "${%s}" s in
  let matrix s = Printf.sprintf "${%s}" s in
  [
    ( "gl_cachekey_opambin",
      Jg_types.Tstr (join (cachekey_opambin ~read_script ~input ~matrix)) );
    ( "gl_cachekey_ci_inputs",
      Jg_types.Tstr (join (cachekey_ci_inputs ~input ~matrix)) );
    ( "gl_cachekey_vsstudio",
      Jg_types.Tstr (join (cachekey_vsstudio ~input ~matrix)) );
  ]
