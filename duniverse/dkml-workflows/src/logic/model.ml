(* Useful `dune utop` expressions:


   Workflow_logic.Model.vars_as_object ~filter_dkml_host_abi:(fun _s -> true) ~rewrite_name_value:Workflow_logic.Model.gl_rewrite_name_value ;;

   Workflow_logic.Model.full_matrix_as_list ~filter_dkml_host_abi:(fun _s -> true) ~rewrite_name_value:Workflow_logic.Model.gl_rewrite_name_value ;;
*)
open Astring
open Jingoo

let global_env_vars =
  [
    ("DEFAULT_DKML_COMPILER", "4.12.1-v1.0.2");
    ("PIN_BASE", "v0.14.3");
    ("PIN_BIGSTRINGAF", "0.8.0");
    ("PIN_CORE_KERNEL", "v0.14.2");
    ("PIN_CTYPES_FOREIGN", "0.19.2-windowssupport-r4");
    ("PIN_CTYPES", "0.19.2-windowssupport-r4");
    ("PIN_CURLY", "0.2.1-windows-env_r2");
    ("PIN_DIGESTIF", "1.0.1");
    ("PIN_DUNE", "2.9.3");
    ("PIN_OCAMLBUILD", "0.14.0");
    ("PIN_OCAMLFIND", "1.9.1");
    ("PIN_OCP_INDENT", "1.8.2-windowssupport");
    ("PIN_PPX_EXPECT", "v0.14.1");
    ("PIN_PTIME", "0.8.6-msvcsupport");
    ("PIN_TIME_NOW", "v0.14.0");
  ]

let required_msys2_packages =
  (*
   Install utilities
   wget: Needed for the Windows Opam download-command
   make: Needed for OCaml ./configure + make
   pkg-config: conf-pkg-config is used by many OCaml packages like digestif.
   rsync: On Windows the `cp` fallback can fail; loosely related to
        https://github.com/ocaml/opam/issues/4080
   diffutils: Needed for diff, which is needed for Opam
   patch: Needed for Opam
   unzip: Needed for Opam
   git: Needed for Opam
   tar: For Opam 2.0 from fdopen, we need MSYS2/Cygwin tar that can handle
      Unix paths like /tmp.
   xz is not for OCaml; just to get opam64.tar.xz from fdopen *)
  Jg_types.Tlist
    (List.map
       (fun s -> Jg_types.Tstr s)
       [
         "wget";
         "make";
         "rsync";
         "diffutils";
         "patch";
         "unzip";
         "git";
         "tar";
         "xz";
       ])

let bootstrap_opam_version = Jg_types.Tstr "2.2.0-dkml20220801T155940Z"

let matrix =
  [
    (*
       ------------
       windows-2019
         https://github.com/actions/virtual-environments/blob/main/images/win/Windows2019-Readme.md
       ------------

       Windows needs to have a short OPAMROOT to minimize risk of exceeding 260 character
       limit.

       But GitLab CI can't cache anything unless it is in the project directory, so GitLab CI
       may encounter 260-character limit problems.

      So the optional `opam_root_cacheable` (which defaults to `opam_root`) is different for
      GitLab (gl) on Windows than `opam_root` so that the former can be in the project directory
      while the latter is a short path that avoids 260 char limit.
    *)
    [
      ("abi_pattern", Jg_types.Tstr {|win32-windows_x86|});
      ("gh_os", Jg_types.Tstr {|windows-2019|} (* 2019 has Visual Studio 2019 *));
      ("gh_unix_shell", Jg_types.Tstr {|msys2 {0}|});
      ("msys2_system", Jg_types.Tstr {|MINGW32|});
      ("msys2_packages", Jg_types.Tstr {|mingw-w64-i686-pkg-config|});
      ("exe_ext", Jg_types.Tstr {|.exe|});
      ("bootstrap_opam_version", bootstrap_opam_version);
      ("opam_abi", Jg_types.Tstr {|windows_x86|});
      ("dkml_host_abi", Jg_types.Tstr {|windows_x86|});
      ("gh_opam_root", Jg_types.Tstr {|D:/.opam|});
      ("gl_opam_root", Jg_types.Tstr {|C:/o|});
      ("gl_opam_root_cacheable", Jg_types.Tstr {|${CI_PROJECT_DIR}/.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|${env:PC_PROJECT_DIR}/.ci/o|});
      ("vsstudio_hostarch", Jg_types.Tstr {|x64|});
      ("vsstudio_arch", Jg_types.Tstr {|x86|});
      ("ocaml_options", Jg_types.Tstr {|ocaml-option-32bit|});
    ];
    [
      ("abi_pattern", Jg_types.Tstr {|win32-windows_x86_64|});
      ("gh_os", Jg_types.Tstr {|windows-2019|} (* 2019 has Visual Studio 2019 *));
      ("gh_unix_shell", Jg_types.Tstr {|msys2 {0}|});
      ("msys2_system", Jg_types.Tstr {|CLANG64|});
      ("msys2_packages", Jg_types.Tstr {|mingw-w64-clang-x86_64-pkg-config|});
      ("exe_ext", Jg_types.Tstr {|.exe|});
      ("bootstrap_opam_version", bootstrap_opam_version);
      ("opam_abi", Jg_types.Tstr {|windows_x86_64|});
      ("dkml_host_abi", Jg_types.Tstr {|windows_x86_64|});
      ("gh_opam_root", Jg_types.Tstr {|D:/.opam|});
      ("gl_opam_root", Jg_types.Tstr {|C:/o|});
      ("gl_opam_root_cacheable", Jg_types.Tstr {|${CI_PROJECT_DIR}/.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|${env:PC_PROJECT_DIR}/.ci/o|});
      ("vsstudio_hostarch", Jg_types.Tstr {|x64|});
      ("vsstudio_arch", Jg_types.Tstr {|x64|});
    ]
    (* Unnecessary to use VS 14.16, but it serves as a good template for
       other (future) VS versions.
       ;[("gh_os", Jg_types.Tstr "windows-2019"   (* 2019 has Visual Studio 2019 *))
         ; ("abi_pattern", Jg_types.Tstr {|win32_1416-windows_64|} (* VS2017 compiler available to VS2019 *))
         ...
         ; ("vsstudio_hostarch", Jg_types.Tstr {|x64|})
         ; ("vsstudio_arch", Jg_types.Tstr {|x64|})
         ; ("vsstudio_dir", Jg_types.Tstr {|'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'|})
         ; ("vsstudio_vcvarsver", Jg_types.Tstr {|'14.16'|})
         ; ("vsstudio_winsdkver", Jg_types.Tstr {|'10.0.18362.0'|})
         ; ("vsstudio_msvspreference", Jg_types.Tstr {|'VS16.5'|})
         ; ("vsstudio_cmakegenerator", Jg_types.Tstr {|'Visual Studio 16 2019'|})
         ]
    *)

    (*
        ------------
        windows-2022
          https://github.com/actions/virtual-environments/blob/main/images/win/Windows2022-Readme.md
        ------------

        Disabled because haven't done opam log dumps on failure for
        `opam upgrade`. See https://github.com/diskuv/dkml-component-ocamlcompiler/runs/6059642542?check_suite_focus=true
        ;[("gh_os", Jg_types.Tstr "windows-2022")
          ; ("abi_pattern", Jg_types.Tstr {|win32_2022-windows_x86_64|})
          ...
          ; ("vsstudio_hostarch", Jg_types.Tstr {|x64|})
          ; ("vsstudio_arch", Jg_types.Tstr {|x64|})
          ; ("vsstudio_dir", Jg_types.Tstr {|'C:\Program Files\Microsoft Visual Studio\2022\Enterprise'|})
          ; ("vsstudio_vcvarsver", Jg_types.Tstr {|'14.29'|})
          ; ("vsstudio_winsdkver", Jg_types.Tstr {|'10.0.20348.0'|})
          ; ("vsstudio_msvspreference", Jg_types.Tstr {|'VS16.11'|})
          ; ("vsstudio_cmakegenerator", Jg_types.Tstr {|'Visual Studio 17 2022'|})
          ]
        *);
    [
      ("abi_pattern", Jg_types.Tstr {|macos-darwin_all|});
      ("gh_os", Jg_types.Tstr "macos-latest");
      ("gl_image", Jg_types.Tstr "macos-11-xcode-12");
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("bootstrap_opam_version", bootstrap_opam_version);
      ("dkml_host_abi", Jg_types.Tstr {|darwin_x86_64|});
      ("gh_opam_root", Jg_types.Tstr {|/Users/runner/.opam|});
      ("gl_opam_root", Jg_types.Tstr {|${CI_PROJECT_DIR}/.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|${PC_PROJECT_DIR}/.ci/o|});
    ]
    (* --- NOT APPLICABLE: BUG FIXED ---
       OCaml 4.12.1 can't compile on manylinux2014 x86 (32-bit). It gives:

           /opt/rh/devtoolset-10/root/usr/bin/gcc -c -O2 -fno-strict-aliasing -fwrapv -Wall -Wdeclaration-after-statement -fno-common -fexcess-precision=standard -fno-tree-vrp -ffunction-sections -g -Wno-format -D_FILE_OFFSET_BITS=64 -D_REENTRANT -DCAML_NAME_SPACE   -DCAMLDLLIMPORT= -DNATIVE_CODE -DTARGET_amd64 -DMODEL_default -DSYS_linux   -o signals_nat.n.o signals_nat.c
           In file included from signals_nat.c:35:
           signals_nat.c: In function ‘segv_handler’:
           signals_osdep.h:34:72: error: ‘REG_CR2’ undeclared (first use in this function); did you mean ‘REG_CS’?
             34 | define CONTEXT_FAULTING_ADDRESS ((char * )context->uc_mcontext.gregs[REG_CR2])
                 |                                                                        ^~~~~~~
           signals_nat.c:207:16: note: in expansion of macro ‘CONTEXT_FAULTING_ADDRESS’
             207 |   fault_addr = CONTEXT_FAULTING_ADDRESS;
                 |                ^~~~~~~~~~~~~~~~~~~~~~~~
           signals_osdep.h:34:72: note: each undeclared identifier is reported only once for each function it appears in
             34 | define CONTEXT_FAULTING_ADDRESS ((char * )context->uc_mcontext.gregs[REG_CR2])
                 |                                                                        ^~~~~~~
           signals_nat.c:207:16: note: in expansion of macro ‘CONTEXT_FAULTING_ADDRESS’
             207 |   fault_addr = CONTEXT_FAULTING_ADDRESS;
                 |                ^~~~~~~~~~~~~~~~~~~~~~~~
           signals_osdep.h:32:50: error: ‘REG_RSP’ undeclared (first use in this function); did you mean ‘REG_ESP’?
             32 | define CONTEXT_SP (context->uc_mcontext.gregs[REG_RSP])
                 |                                                  ^~~~~~~
           signals_nat.c:210:33: note: in expansion of macro ‘CONTEXT_SP’
             210 |       && (uintnat)fault_addr >= CONTEXT_SP - EXTRA_STACK
                 |                                 ^~~~~~~~~~
           signals_osdep.h:31:50: error: ‘REG_RIP’ undeclared (first use in this function); did you mean ‘REG_EIP’?
             31 | define CONTEXT_PC (context->uc_mcontext.gregs[REG_RIP])
                 |                                                  ^~~~~~~
           signals_nat.c:212:49: note: in expansion of macro ‘CONTEXT_PC’
             212 |       && caml_find_code_fragment_by_pc((char * ) CONTEXT_PC) != NULL
                 |                                                 ^~~~~~~~~~
           make[1]: *** [signals_nat.n.o] Error 1
           make[1]: Leaving directory `/work/opamroot/dkml/src-ocaml/runtime'
           make: *** [makeruntimeopt] Error 2
           FATAL: make opt-core failed *);
    (*
       Linux
       -----

       OPAMROOT needs to be a local directory of the checked-out code because dockcross only
       mounts that directory as /work.
    *)
    [
      ("abi_pattern", Jg_types.Tstr {|manylinux2014-linux_x86|});
      ("gh_os", Jg_types.Tstr "ubuntu-latest");
      ("comment", Jg_types.Tstr {|(CentOS 7, etc.)|});
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("bootstrap_opam_version", bootstrap_opam_version);
      ("dkml_host_abi", Jg_types.Tstr {|linux_x86|});
      ("gh_opam_root", Jg_types.Tstr {|.ci/o|});
      ("gl_opam_root", Jg_types.Tstr {|.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|.ci/o|});
      ("in_docker", Jg_types.Tstr {|true|});
      ("dockcross_image", Jg_types.Tstr {|dockcross/manylinux2014-x86|});
      (* Gets rid of: WARNING: The requested image's platform (linux/386) does not match the detected host platform (linux/amd64) and no specific platform was requested *)
      ("dockcross_run_extra_args", Jg_types.Tstr {|--platform linux/386|});
    ]
    (* ("gh_os", ubuntu-latest
        ; ("abi_pattern", Jg_types.Tstr {|manylinux_2_24-linux_x86|})
        ; ("comment", Jg_types.Tstr {|(glibc>=2.24, Debian 9, etc.)|})
        ; ("gh_unix_shell", Jg_types.Tstr {|sh|})
        ; ("bootstrap_opam_version", bootstrap_opam_version)
        ; ("dkml_host_abi", Jg_types.Tstr {|linux_x86|})
        ; ("gh_opam_root", Jg_types.Tstr {|.ci/o|})
        ; ("gl_opam_root", Jg_types.Tstr {|.ci/o|})
        ; ("pc_opam_root", Jg_types.Tstr {|.ci/o|})
        ; ("docker_runner", Jg_types.Tstr {|docker run --platform linux/386 --rm -v $GITHUB_WORKSPACE:/work --workdir=/work quay.io/pypa/manylinux_2_24_i686 linux32|})
        ; ("in_docker", Jg_types.Tstr {|true|})
          ] *);
    [
      ("abi_pattern", Jg_types.Tstr {|manylinux2014-linux_x86_64|});
      ("gh_os", Jg_types.Tstr "ubuntu-latest");
      ("comment", Jg_types.Tstr {|(CentOS 7, etc.)|});
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("bootstrap_opam_version", bootstrap_opam_version);
      ("dkml_host_abi", Jg_types.Tstr {|linux_x86_64|});
      ("gh_opam_root", Jg_types.Tstr {|.ci/o|});
      ("gl_opam_root", Jg_types.Tstr {|.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|.ci/o|});
      ("dockcross_image", Jg_types.Tstr {|dockcross/manylinux2014-x64|});
      (* Use explicit platform because setup-dkml.sh will bypass 'dockcross' script (which hardcodes the --platform)
         when the invoking user is root. In that situation the following arguments are used. *)
      ("dockcross_run_extra_args", Jg_types.Tstr {|--platform linux/amd64|});
      ("in_docker", Jg_types.Tstr {|true|});
    ];
  ]

module Aggregate = struct
  type t = {
    mutable dkml_host_os_opt : Jg_types.tvalue option;
    mutable dkml_host_abi_opt : string option;
    mutable opam_root_opt : string option;
    mutable opam_root_cacheable_opt : string option;
  }

  let create () =
    {
      dkml_host_os_opt = None;
      dkml_host_abi_opt = None;
      opam_root_opt = None;
      opam_root_cacheable_opt = None;
    }

  let capture ~name ~value t =
    let value_if_string value =
      if Jg_types.type_string_of_tvalue value = "string" then
        Some (Jg_types.unbox_string value)
      else None
    in
    let value_as_string = value_if_string value in
    (* Capture scalar values *)
    (match name with
    | "dkml_host_abi" -> t.dkml_host_abi_opt <- value_as_string
    | "opam_root" -> t.opam_root_opt <- value_as_string
    | "opam_root_cacheable" -> t.opam_root_cacheable_opt <- value_as_string
    | _ -> ());
    (* Capture dkml_host_os *)
    match (name, Option.map (String.cuts ~sep:"_") value_as_string) with
    | "dkml_host_abi", Some (value_head :: _value_tail) ->
        t.dkml_host_os_opt <- Some (Jg_types.Tstr value_head)
    | _ -> ()

  let dkml_host_abi_opt t = t.dkml_host_abi_opt

  let opam_root_opt t = t.opam_root_opt

  let opam_root_cacheable_opt t = t.opam_root_cacheable_opt

  let dump t =
    match
      ( t.dkml_host_os_opt,
        t.dkml_host_abi_opt,
        t.opam_root_opt,
        t.opam_root_cacheable_opt )
    with
    | ( Some dkml_host_os,
        Some dkml_host_abi,
        Some opam_root,
        opam_root_cacheable_opt ) ->
        let opam_root_cacheable =
          Option.fold ~none:opam_root
            ~some:(fun opam_root_cacheable -> opam_root_cacheable)
            opam_root_cacheable_opt
        in
        [
          ("dkml_host_abi", Jg_types.Tstr dkml_host_abi);
          ("dkml_host_os", dkml_host_os);
          ("opam_root", Jg_types.Tstr opam_root);
          ("opam_root_cacheable", Jg_types.Tstr opam_root_cacheable);
        ]
    | Some _, None, Some _, _ ->
        failwith "Expected dkml_host_abi would be found"
    | Some _, Some _, None, _ -> failwith "Expected opam_root would be found"
    | None, Some _, Some _, _ ->
        failwith "Expected dkml_host_os would be derived"
    | _ ->
        failwith
          "Expected dkml_host_abi and opam_root would be found and \
           dkml_host_os would be derived"
end

(**

  The field [opam_root_cacheable] will default to [opam_root] unless explicitly
  set.

  {v
    { vars: [
        { name: "abi_pattern", value: 'win32-windows_x86' },
        { name: "gh_unix_shell", value: 'msys2 {0}' },
        { name: "msys2_system", value: 'MINGW32' },
        { name: "msys2_packages", value: 'mingw-w64-i686-pkg-config' },
        { name: "exe_ext", value: '.exe' },
        { name: "bootstrap_opam_version", value: '2.2.0-dkml20220801T155940Z' },
        { name: "opam_abi", value: 'windows_x86' },
        { name: "dkml_host_abi", value: 'windows_x86' },
        { name: "opam_root", value: '${CI_PROJECT_DIR}/.ci/o' },
        { name: "vsstudio_hostarch", value: 'x64' },
        { name: "vsstudio_arch", value: 'x86' },
        { name: "ocaml_options", value: 'ocaml-option-32bit' },
        ...
      ],
      dkml_host_abi: "windows_x86",
      dkml_host_os: "windows",
      opam_root: "${CI_PROJECT_DIR}/.ci/o",
      opam_root_cacheable: "${CI_PROJECT_DIR}/.ci/o",
  v}
*)
let full_matrix_as_list ~filter_dkml_host_abi ~rewrite_name_value =
  List.filter_map
    (fun matrix_item ->
      let aggregate = Aggregate.create () in
      let vars =
        Jg_types.Tlist
          (List.filter_map
             (fun (name, value) ->
               (* make name value pair unless ~rewrite_name_value is None *)
               match rewrite_name_value ~name ~value () with
               | None ->
                   (* capture aggregates *)
                   Aggregate.capture ~name ~value aggregate;
                   None
               | Some (name', value') ->
                   (* capture aggregates (after rewriting!) *)
                   Aggregate.capture ~name:name' ~value:value' aggregate;
                   Some
                     (Jg_types.Tobj
                        [ ("name", Jg_types.Tstr name'); ("value", value') ]))
             matrix_item)
      in
      match Aggregate.dkml_host_abi_opt aggregate with
      | Some dkml_host_abi ->
          if filter_dkml_host_abi dkml_host_abi then
            Some (Jg_types.Tobj ([ ("vars", vars) ] @ Aggregate.dump aggregate))
          else None
      | None -> None)
    matrix

(**

  {v
    windows_x86: {
      abi_pattern: 'win32-windows_x86',
      gh_unix_shell: 'msys2 {0}',
      msys2_system: 'MINGW32',
      msys2_packages: 'mingw-w64-i686-pkg-config',
      exe_ext: '.exe',
      bootstrap_opam_version: '2.2.0-dkml20220801T155940Z',
      opam_abi: 'windows_x86',
      dkml_host_abi: 'windows_x86',
      opam_root: '${CI_PROJECT_DIR}/.ci/o',
      vsstudio_hostarch: 'x64',
      vsstudio_arch: 'x86',
      ocaml_options: 'ocaml-option-32bit' }
  v}
*)
let vars_as_object ~filter_dkml_host_abi ~rewrite_name_value =
  let matrix = full_matrix_as_list ~filter_dkml_host_abi ~rewrite_name_value in
  let filter_vars f (vars : Jg_types.tvalue list) : Jg_types.tvalue list =
    List.filter
      (function
        | Jg_types.Tobj
            [ ("name", Jg_types.Tstr name); ("value", Jg_types.Tstr value) ] ->
            f ~name ~value
        | _ -> false)
      vars
  in
  let vars =
    List.map
      (function
        | Jg_types.Tobj
            [
              ("vars", Jg_types.Tlist vars);
              ("dkml_host_abi", Jg_types.Tstr dkml_host_abi);
              ("dkml_host_os", Jg_types.Tstr dkml_host_os);
              ("opam_root", Jg_types.Tstr _opam_root);
              ("opam_root_cacheable", Jg_types.Tstr opam_root_cacheable);
            ] ->
            ( dkml_host_abi,
              Jg_types.Tobj
                [
                  ("name", Jg_types.Tstr "dkml_host_os");
                  ("value", Jg_types.Tstr dkml_host_os);
                ]
              :: Jg_types.Tobj
                   [
                     ("name", Jg_types.Tstr "opam_root_cacheable");
                     ("value", Jg_types.Tstr opam_root_cacheable);
                   ]
              :: filter_vars
                   (fun ~name ~value:_ ->
                     not (String.equal name "opam_root_cacheable"))
                   vars )
        | _ ->
            failwith
              "Expecting [('vars', Tlist varlist); ('dkml_host_abi', ...); \
               ('dkml_host_os', ...); ('opam_root', ...); \
               ('opam_root_cacheable', ...); ...] where vars is the first item")
      matrix
  in
  let f_vars_to_obj = function
    | Jg_types.Tobj [ ("name", Jg_types.Tstr name'); ("value", value') ] ->
        (name', value')
    | v ->
        let msg =
          Format.asprintf
            "Expecting vars is a list of [('name', varlist); ('value', \
             value)]. Instead a list item was:@ %a"
            Jg_types.pp_tvalue v
        in
        prerr_endline ("FATAL: " ^ msg);
        failwith msg
  in
  Jg_types.Tobj
    (List.map
       (fun (dkml_host_abi, vars) ->
         (dkml_host_abi, Jg_types.Tobj (List.map f_vars_to_obj vars)))
       vars)

let gh_rewrite_name_value ~name ~value () =
  match
    ( name,
      String.is_prefix ~affix:"gl" name || String.is_prefix ~affix:"pc" name )
  with
  | _, true -> None
  | "gh_opam_root", _ -> Some ("opam_root", value)
  | "gh_opam_root_cacheable", _ -> Some ("opam_root_cacheable", value)
  | _ -> Some (name, value)

let gl_rewrite_name_value ~name ~value () =
  match
    ( name,
      String.is_prefix ~affix:"gh" name || String.is_prefix ~affix:"pc" name )
  with
  | _, true -> None
  | "gl_opam_root", _ -> Some ("opam_root", value)
  | "gl_opam_root_cacheable", _ -> Some ("opam_root_cacheable", value)
  | _ -> Some (name, value)

let pc_rewrite_name_value ~name ~value () =
  match
    ( name,
      String.is_prefix ~affix:"gh" name || String.is_prefix ~affix:"gl" name )
  with
  | _, true -> None
  | "pc_opam_root", _ -> Some ("opam_root", value)
  | "pc_opam_root_cacheable", _ -> Some ("opam_root_cacheable", value)
  | _ -> Some (name, value)

let model ~filter_dkml_host_abi ~read_script =
  [
    ( "global_env_vars",
      Jg_types.Tlist
        (List.map
           (fun (name, value) ->
             Jg_types.Tobj
               [ ("name", Jg_types.Tstr name); ("value", Jg_types.Tstr value) ])
           global_env_vars) );
    ( "gh_matrix",
      Jg_types.Tlist
        (full_matrix_as_list ~filter_dkml_host_abi
           ~rewrite_name_value:gh_rewrite_name_value) );
    ( "gh_vars",
      vars_as_object ~filter_dkml_host_abi
        ~rewrite_name_value:gh_rewrite_name_value );
    ( "gl_matrix",
      Jg_types.Tlist
        (full_matrix_as_list ~filter_dkml_host_abi
           ~rewrite_name_value:gl_rewrite_name_value) );
    ( "gl_vars",
      vars_as_object ~filter_dkml_host_abi
        ~rewrite_name_value:gl_rewrite_name_value );
    ( "pc_matrix",
      Jg_types.Tlist
        (full_matrix_as_list ~filter_dkml_host_abi
           ~rewrite_name_value:pc_rewrite_name_value) );
    ( "pc_vars",
      vars_as_object ~filter_dkml_host_abi
        ~rewrite_name_value:pc_rewrite_name_value );
    ("required_msys2_packages", required_msys2_packages);
  ]
  @ Scripts.to_vars read_script
  @ Typography.vars
  @ Caching.static_vars
  @ Caching.gh_cachekeys read_script
  @ Caching.gl_cachekeys read_script
