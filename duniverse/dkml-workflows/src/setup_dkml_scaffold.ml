open Bos

let ( let* ) = Rresult.R.bind

type gh_config = { gh_dir : string; gh_output_option : string }

let gh_configs =
  [
    { gh_dir = "gh-darwin"; gh_output_option = "darwin" };
    { gh_dir = "gh-linux"; gh_output_option = "linux" };
    { gh_dir = "gh-windows"; gh_output_option = "windows" };
  ]

let scaffold_gh ~output_dir () =
  let rec helper = function
    | [] -> Ok ()
    | { gh_dir; gh_output_option } :: tl ->
        let gh_dir = Fpath.(output_dir / gh_dir) in
        let gh_action_file = Fpath.(gh_dir / "action.yml") in
        let gh_dune_file = Fpath.(gh_dir / "dune") in
        let action_content = Printf.sprintf {||} in
        let dune_content =
          Printf.sprintf
            {|
(rule
(alias gen-dkml)
(target action.gen.yml)
(action
  (setenv
  OCAMLRUNPARAM
  b
  (run %%{bin:gh-setup-dkml-action-yml.exe} --output-%s %%{target}))))

(rule
(alias gen-dkml)
(action
  (diff action.yml action.gen.yml)))
|}
            gh_output_option
        in
        let* (_exists : bool) = OS.Dir.create gh_dir in
        let* () = OS.File.write gh_action_file action_content in
        let* () = OS.File.write gh_dune_file dune_content in
        helper tl
  in
  helper gh_configs

let scaffold_gl ~output_dir () =
  let gl_dir = Fpath.(output_dir / "gl") in
  let gl_include_file = Fpath.(gl_dir / "setup-dkml.gitlab-ci.yml") in
  let gl_dune_file = Fpath.(gl_dir / "dune") in
  let include_content = Printf.sprintf {||} in
  let dune_content =
    Printf.sprintf
      {|
(rule
(target setup-dkml.gen.gitlab-ci.yml)
(alias gen-dkml)
(action
  (setenv
  OCAMLRUNPARAM
  b
  (run
    %%{bin:gl-setup-dkml-yml.exe}
    ; Exclude macOS until you have a https://gitlab.com/gitlab-com/runner-saas-macos-access-requests/-/issues approved
    --exclude-macos
    --output-file
    %%{target}))))

(rule
(alias gen-dkml)
(action
  (diff setup-dkml.gitlab-ci.yml setup-dkml.gen.gitlab-ci.yml)))
|}
  in
  let* (_exists : bool) = OS.Dir.create gl_dir in
  let* () = OS.File.write gl_include_file include_content in
  let* () = OS.File.write gl_dune_file dune_content in
  Ok ()

let encode encoder what =
  match Uutf.encode encoder what with
  | `Ok -> ()
  | `Partial -> failwith "unexpected `Partial while writing Unicode"

let scaffold_pc ~output_dir () =
  let pc_dir = Fpath.(output_dir / "pc") in
  (* The setup-dkml-*.ps1 is a UTF-16BE with BOM empty file. *)
  let pc_windows_x86_64_file =
    Fpath.(pc_dir / "setup-dkml-windows_x86_64.ps1")
  in
  let pc_windows_x86_file = Fpath.(pc_dir / "setup-dkml-windows_x86.ps1") in
  let buf = Buffer.create 4 in
  let encoder = Uutf.encoder `UTF_16BE (`Buffer buf) in
  encode encoder (`Uchar Uutf.u_bom);
  encode encoder `End;
  let ps1_content = Bytes.to_string (Buffer.to_bytes buf) in
  let pc_dune_file = Fpath.(pc_dir / "dune") in
  let dune_content =
    Printf.sprintf
      {|
(rule
(target setup-dkml-windows_x86-gen.ps1)
(action
  (setenv
  OCAMLRUNPARAM
  b
  (run %%{bin:pc-setup-dkml.exe} --output-windows_x86 %%{target}))))

(rule
(target setup-dkml-windows_x86_64-gen.ps1)
(action
  (setenv
  OCAMLRUNPARAM
  b
  (run %%{bin:pc-setup-dkml.exe} --output-windows_x86_64 %%{target}))))

(rule
(alias gen-dkml)
(action
  (diff setup-dkml-windows_x86.ps1 setup-dkml-windows_x86-gen.ps1)))

(rule
(alias gen-dkml)
(action
  (diff setup-dkml-windows_x86_64.ps1 setup-dkml-windows_x86_64-gen.ps1)))
  |}
  in
  let* (_exists : bool) = OS.Dir.create pc_dir in
  let* () = OS.File.write pc_windows_x86_64_file ps1_content in
  let* () = OS.File.write pc_windows_x86_file ps1_content in
  let* () = OS.File.write pc_dune_file dune_content in
  Ok ()

let scaffold ~output_dir () =
  let* (_exists : bool) = OS.Dir.create output_dir in
  let* () = scaffold_gh ~output_dir () in
  let* () = scaffold_gl ~output_dir () in
  let* () = scaffold_pc ~output_dir () in
  Ok ()

let () =
  (* Parse args *)
  let exe_name = "generate-setup-dkml-scaffold.exe" in
  let usage = Printf.sprintf "%s --output-file OUTPUT_FILE" exe_name in
  let anon _s = failwith "No command line arguments are supported" in
  let output_dir = ref "ci/setup-dkml" in
  Arg.parse
    [
      ( "--output-dir",
        Set_string output_dir,
        "Output directory. Defaults to " ^ !output_dir );
    ]
    anon exe_name;
  if String.equal "" !output_dir then failwith usage;
  let res = scaffold ~output_dir:(Fpath.v !output_dir) () in
  Rresult.R.failwith_error_msg res
