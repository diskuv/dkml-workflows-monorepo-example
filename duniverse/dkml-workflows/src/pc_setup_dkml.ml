open Jingoo

let windows_tmpl ~dkml_host_abi =
  let script =
    Workflow_content.Tmpl_common.get_template_file
      ~tmpl_file:(Printf.sprintf "pc/setup-dkml-%s.ps1" dkml_host_abi)
  in
  Workflow_logic.Scripts.encode_as_utf8 script

let unix_tmpl ~dkml_host_abi =
  let script =
    Workflow_content.Tmpl_common.get_template_file
      ~tmpl_file:(Printf.sprintf "pc/setup-dkml-%s.sh" dkml_host_abi)
  in
  Workflow_logic.Scripts.encode_as_utf8 script

let env = { Jg_types.std_env with autoescape = false }

let models =
  Workflow_logic.Model.model
    ~filter_dkml_host_abi:(fun _s -> true)
    ~read_script:Workflow_content.Scripts.read

let windows_action ~dkml_host_abi filename =
  let oc = open_out_bin filename in
  let tmpl = windows_tmpl ~dkml_host_abi in
  let content = Jg_template.from_string ~env ~models tmpl in
  output_string oc (Workflow_logic.Scripts.encode_as_powershell content);
  close_out oc

let unix_action ~dkml_host_abi filename =
  let oc = open_out_bin filename in
  let tmpl = unix_tmpl ~dkml_host_abi in
  let content = Jg_template.from_string ~env ~models tmpl in
  output_string oc (Workflow_logic.Scripts.encode_as_utf8 content);
  close_out oc

let () =
  (* Parse args *)
  let exe_name = "pc-setup-dkml" in
  let usage =
    Printf.sprintf
      "%s [--output-windows_x86 OUTPUT_FILE.ps1] [--output-windows_x86_64 \
       OUTPUT_FILE.ps1] [--output-darwin_x86_64 OUTPUT_FILE.sh] \
       [--output-linux_x86 OUTPUT_FILE.sh] [--output-linux_x86_64 \
       OUTPUT_FILE.sh]\n\
       At least one --output-<ABI> option must be selected." exe_name
  in
  let anon _s = failwith "No command line arguments are supported" in
  let actions = ref [] in
  let output_unix_abi_arg ~dkml_host_abi ~descr =
    ( "--output-" ^ dkml_host_abi,
      Arg.String
        (fun filename ->
          actions := (fun () -> unix_action ~dkml_host_abi filename) :: !actions),
      "Output POSIX shell script for " ^ descr )
  in
  Arg.parse
    [
      ( "--output-windows_x86",
        String
          (fun filename ->
            actions :=
              (fun () -> windows_action ~dkml_host_abi:"windows_x86" filename)
              :: !actions),
        "Output Powershell script for Windows 32-bit" );
      ( "--output-windows_x86_64",
        String
          (fun filename ->
            actions :=
              (fun () ->
                windows_action ~dkml_host_abi:"windows_x86_64" filename)
              :: !actions),
        "Output Powershell script for Windows 64-bit" );
      output_unix_abi_arg ~dkml_host_abi:"darwin_x86_64"
        ~descr:"macOS/Intel (or macOS/ARM64 with Rosetta emulator)";
      output_unix_abi_arg ~dkml_host_abi:"linux_x86"
        ~descr:"Linux on 32-bit Intel/AMD";
      output_unix_abi_arg ~dkml_host_abi:"linux_x86_64"
        ~descr:"Linux on 64-bit Intel/AMD";
    ]
    anon exe_name;
  if !actions = [] then failwith usage;
  (* Generate *)
  List.iter (fun f -> f ()) !actions
