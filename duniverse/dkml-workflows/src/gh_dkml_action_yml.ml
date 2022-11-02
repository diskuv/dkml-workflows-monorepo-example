open Jingoo

let env = { Jg_types.std_env with autoescape = false }

let action ~ofile ~tmpl ~phase =
  (* Generate *)
  let tmpl_file = Printf.sprintf "%s/%s/action.yml" tmpl phase in
  let tmpl = Workflow_content.Tmpl_common.get_template_file ~tmpl_file in
  let models =
    Workflow_logic.Model.model
      ~filter_dkml_host_abi:(fun _s -> true)
      ~read_script:Workflow_content.Scripts.read
  in
  let oc = open_out_bin ofile in
  output_string oc (Jg_template.from_string ~env ~models tmpl);
  close_out oc

let () =
  (* Parse args *)
  let exe_name = "gh-dkml-action-yml" in
  let usage =
    Printf.sprintf
      "%s [--phase pre|post] [--output-windows action.yml] [--output-linux \
       action.yml] [--output-darwin action.yml]\n\
       At least one --output-<OS> option must be specified" exe_name
  in
  let anon _s = failwith "No command line arguments are supported" in
  let phase = ref "" in
  let actions : (phase:string -> unit -> unit) list ref = ref [] in
  Arg.parse
    [
      ( "--phase",
        Set_string phase,
        "Set the GitHub Action phase. Either 'pre' (setup) or 'post' (teardown)"
      );
      ( "--output-linux",
        String
          (fun arg ->
            actions :=
              (fun ~phase () -> action ~ofile:arg ~phase ~tmpl:"gh-linux")
              :: !actions),
        "Create a Linux GitHub Actions action.yml file" );
      ( "--output-windows",
        String
          (fun arg ->
            actions :=
              (fun ~phase () -> action ~ofile:arg ~phase ~tmpl:"gh-windows")
              :: !actions),
        "Create a Windows GitHub Actions action.yml file" );
      ( "--output-darwin",
        String
          (fun arg ->
            actions :=
              (fun ~phase () -> action ~ofile:arg ~phase ~tmpl:"gh-darwin")
              :: !actions),
        "Create a Darwin GitHub Actions action.yml file" );
    ]
    anon exe_name;
  if String.equal "" !phase then (
    prerr_endline ("FATAL: " ^ usage);
    exit 3);
  if !actions = [] then (
    prerr_endline ("FATAL: " ^ usage);
    exit 3);
  (* Run all the actions *)
  List.iter (fun action -> action ~phase:!phase ()) !actions
