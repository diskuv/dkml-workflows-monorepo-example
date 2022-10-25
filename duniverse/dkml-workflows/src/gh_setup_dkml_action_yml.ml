open Jingoo

let env = { Jg_types.std_env with autoescape = false }

let action ~output_file ~tmpl_file =
  (* Generate *)
  let tmpl = Workflow_content.Tmpl_common.get_template_file ~tmpl_file in
  let models =
    Workflow_logic.Model.model
      ~filter_dkml_host_abi:(fun _s -> true)
      ~read_script:Workflow_content.Scripts.read
  in
  let oc = open_out_bin output_file in
  output_string oc (Jg_template.from_string ~env ~models tmpl);
  close_out oc

let () =
  (* Parse args *)
  let exe_name = "gh-setup-dkml-action-yml.exe" in
  let usage =
    Printf.sprintf
      "%s [--output-windows action.yml] [--output-linux action.yml] \
       [--output-darwin action.yml]\n\
       At least one --output-<OS> option must be specified" exe_name
  in
  let anon _s = failwith "No command line arguments are supported" in
  let actions : (unit -> unit) list ref = ref [] in
  Arg.parse
    [
      ( "--output-linux",
        String
          (fun arg ->
            actions :=
              (fun () ->
                action ~output_file:arg ~tmpl_file:"gh-linux/action.yml")
              :: !actions),
        "Create a Linux GitHub Actions action.yml file" );
      ( "--output-windows",
        String
          (fun arg ->
            actions :=
              (fun () ->
                action ~output_file:arg ~tmpl_file:"gh-windows/action.yml")
              :: !actions),
        "Create a Windows GitHub Actions action.yml file" );
      ( "--output-darwin",
        String
          (fun arg ->
            actions :=
              (fun () ->
                action ~output_file:arg ~tmpl_file:"gh-darwin/action.yml")
              :: !actions),
        "Create a Darwin GitHub Actions action.yml file" );
    ]
    anon exe_name;
  if !actions = [] then (
    prerr_endline ("FATAL: " ^ usage);
    exit 3);
  (* Run all the actions *)
  List.iter (fun action -> action ()) !actions
