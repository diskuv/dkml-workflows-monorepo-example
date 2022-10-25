let parse exe_name =
  (* Parse args *)
  let usage =
    Printf.sprintf
      "%s [--exclude-macos] [--exclude-win-32bit] --output-file OUTPUT_FILE"
      exe_name
  in
  let exclusions : string list ref = ref [] in
  let anon _s = failwith "No command line arguments are supported" in
  let output_file = ref "" in
  Arg.parse
    [
      ( "--exclude-macos",
        Unit
          (fun () ->
            exclusions := "darwin_x86_64" :: "darwin_arm64" :: !exclusions),
        "Exclude darwin_x86_64 and darwin_arm64 as hosts" );
      ( "--exclude-win-32bit",
        Unit (fun () -> exclusions := "windows_x86" :: !exclusions),
        "Exclude windows_x86 as hosts" );
      ("--output-file", Set_string output_file, "Output file");
    ]
    anon exe_name;
  if String.equal "" !output_file then failwith usage;
  let filter_dkml_host_abi abi = not (List.mem abi !exclusions) in
  (filter_dkml_host_abi, !output_file)
