open Astring

let get_template_file ~tmpl_file =
  let unix_tmpl_file = String.map (function '\\' -> '/' | c -> c) tmpl_file
  and windows_tmpl_file =
    String.map (function '/' -> '\\' | c -> c) tmpl_file
  in
  match Tmpl.read unix_tmpl_file with
  | None -> (
      match Tmpl.read windows_tmpl_file with
      | None ->
          failwith
            (Printf.sprintf "There is no template file %s in Tmpl" tmpl_file)
      | Some v -> v)
  | Some v -> v
