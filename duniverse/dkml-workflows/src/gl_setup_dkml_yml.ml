open Jingoo

let tmpl =
  Workflow_content.Tmpl_common.get_template_file
    ~tmpl_file:"gl/setup-dkml.gitlab-ci.yml"

let env = { Jg_types.std_env with autoescape = false }

let () =
  (* Parse args *)
  let filter_dkml_host_abi, output_file =
    Workflow_arg.Arg_common.parse "gl-setup-dkml-yml.exe"
  in
  (* Generate *)
  let models =
    Workflow_logic.Model.model ~filter_dkml_host_abi
      ~read_script:Workflow_content.Scripts.read
  in
  let oc = open_out_bin output_file in
  output_string oc (Jg_template.from_string ~env ~models tmpl);
  close_out oc
