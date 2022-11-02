open Astring
open Jingoo

(** [indent_after_first] indents all lines after the first line.
    
    Blank lines are never indented; that way trailing spaces are
    not introduced by the indenter. *)
let indent_after_first ~pad s =
  String.cuts ~sep:"\n" s
  |> List.mapi (fun i s' ->
         if i > 0 then if String.equal "" s' then "" else pad ^ s' else s')
  |> String.concat ~sep:"\n"

let variations = [ ("gh_", "        "); ("gl_", "      "); ("pc_", "") ]

(** [unix2dos s] converts all LF sequences in [s] into CRLF. Assumes [s] is ASCII encoded. *)
let unix2dos s =
  Stdlib.String.to_seq s
  (* Expand [\n] into [\r\n] *)
  |> Seq.flat_map (function
       | '\n' -> List.to_seq [ '\r'; '\n' ]
       | c -> Seq.return c)
  |> Stdlib.String.of_seq

let cr = Uchar.of_int 0x000D

let lf = Uchar.of_int 0x000A

(* literally from https://erratique.ch/software/uutf/doc/Uutf/index.html#examples *)
let recode ?nln ?encoding out_encoding
    (src : [ `Channel of in_channel | `String of string ])
    (dst : [ `Channel of out_channel | `Buffer of Buffer.t ]) =
  let rec loop d e =
    match Uutf.decode d with
    | `Uchar _ as u ->
        ignore (Uutf.encode e u);
        loop d e
    | `End -> ignore (Uutf.encode e `End)
    | `Malformed _ ->
        ignore (Uutf.encode e (`Uchar Uutf.u_rep));
        loop d e
    | `Await -> assert false
  in
  let d = Uutf.decoder ?nln ?encoding src in
  let e = Uutf.encoder out_encoding dst in
  loop d e

(** Transcode to UTF-8 for output in YAML or processing wiht Jingoo, especially
    Powershell scripts which are usually UTF-16BE or UTF-16LE *)
let encode_as_utf8 script =
  let buf = Buffer.create (String.length script) in
  recode ~nln:(`ASCII lf) `UTF_8 (`String script) (`Buffer buf);
  Bytes.to_string (Buffer.to_bytes buf)

(** Transcode to UTF-16BE with a BOM and CRLF endings which is one of the
    standard encodings for Powershell. *)
let encode_as_powershell script =
  let buf = Buffer.create (String.length script) in
  Uutf.Buffer.add_utf_16be buf Uutf.u_bom;
  recode `UTF_16BE (`String (unix2dos script)) (`Buffer buf);
  Bytes.to_string (Buffer.to_bytes buf)

let f ~read_script (name, scriptname) =
  match read_script scriptname with
  | None -> failwith (Printf.sprintf "The script %s was not found" scriptname)
  | Some script ->
      List.map
        (fun (name_prefix, pad) ->
          (* Transcode to UTF-8 for output in YAML, especially Powershell
             scripts which are usually UTF-16BE or UTF-16LE *)
          let script_utf8 = encode_as_utf8 script in
          (* Indent and return *)
          let indented = indent_after_first ~pad script_utf8 in
          (name_prefix ^ name, Jg_types.Tstr indented))
        variations

let to_vars read_script =
  List.map (f ~read_script)
    [
      ("common_values_script", "common-values.sh");
      ("setup_dkml_script", "setup-dkml.sh");
      ("teardown_dkml_script", "teardown-dkml.sh");
      ("checkout_code_script", "checkout-code.sh");
      ("config_vsstudio_ps1", "config-vsstudio.ps1");
      ("get_msvcpath_cmd", "get-msvcpath.cmd");
      ("msvcenv_awk", "msvcenv.awk");
      ("msvcpath_awk", "msvcpath.awk");
    ]
  |> List.flatten
