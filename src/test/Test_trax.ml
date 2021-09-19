(*
   Unit tests for Trax

   There are not too many tests because we can't guarantee that
   stack backtraces won't change from one version of ocaml to another.
*)

let rec grow_stack n =
  if n > 0 then
    let _, res = grow_stack (n - 1) in
    n, res
  else
    n, Printexc.get_callstack max_int

let test_deduplicate_trace () =
  let _n, raw = grow_stack 10 in
  let trace = Trax.raw_backtrace_to_string raw in
  print_string trace;
  let re = Re.str "... (skipping 9 duplicates)\n" |> Re.compile in
  match Re.matches re trace with
  | [_] -> ()
  | [] -> Alcotest.fail "no matches, should have found one"
  | _ -> Alcotest.fail "multiple matches, should have found one"

let test_manual_trace () =
  try
    Trax.raise "location 1" (Failure "uh oh")
  with e ->
    try
      Trax.raise "location 2" e
    with e ->
      let expected = "\
Failure(\"uh oh\")
location 1
location 2"
      in
      Alcotest.(check string) "equal" expected (Trax.to_string e)

let tests = [
  "deduplicate trace", `Quick, test_deduplicate_trace;
  "manual trace", `Quick, test_manual_trace;
]
