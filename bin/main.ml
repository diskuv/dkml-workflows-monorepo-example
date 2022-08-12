(* Search for README.md in this directory or any parent/grandparent/... directory. *)
let v : (Fpath.t option, string) result =
  let cwd = Sys.getcwd () in
  Diskuvbox.find_up
    ~from_dir:Fpath.(v cwd)
    ~basenames:[ Fpath.v "README.md" ]
    ()

(* Print out the search results *)
let () =
  Fmt.pr "README.md Search Results:@ @[  %a@]@."
    (Rresult.R.pp
       ~ok:Fmt.(option ~none:(const string "No README.md found") Fpath.pp)
       ~error:Fmt.(const string "Error trying to find README.md: " ++ string))
    v
