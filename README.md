OCaml exception tracing [![CircleCI badge](https://circleci.com/gh/mjambon/trax.svg?style=svg)](https://app.circleci.com/pipelines/github/mjambon/trax)
==

This small library is useful in OCaml programs that for some reason
catch exceptions in one spot and reraise them later.

The goal is to produce a useful _execution trace_ that tells the story
of what code was executed and led to the error.

While catching exceptions indiscriminately and reraising them later
should generally be avoided if possible, there are cases where it is
useful. Such cases include:

* computation is sequential but possibly interleaved with other computations
  using many callbacks (promises, continuation-passing style).
* execution of as many independent jobs as possible without
  failing. In such case, catching exceptions for each job and
  capturing a stack trace may be sufficient. If an exception is
  caught early and reraised at the very end, then this library may be
  useful.
* code in which exception handling was not thought out well.

For context, some examples of what works and what doesn't work with
stack traces are given here: https://github.com/mjambon/backtrace

API documentation
--

See [`src/Trax.mli`](https://github.com/mjambon/trax/blob/master/src/lib/Trax.mli).

Example 1: roll-your-own trace, no actual stack backtrace
--

The following shows that we can add code locations to construct our
own trace. This doesn't rely on recording stack backtraces.

```ocaml
let foo x y z =
  ...
  (* some error occurred: add current location to the trace *)
  Trax.raise __LOC__ (Failure "uh oh")

let bar x y z =
  try foo x y z
  with e ->
    (* inspect the exception; requires unwrapping *)
    match Trax.unwrap e with
    | Invalid_arg _ ->
       assert false
    | _ ->
       (* re-raise the exception, adding the current location to the trace *)
       Trax.raise __LOC__ e

let main () =
  try
    ...
    bar x y z
    ...
  with e ->
    Trax.print stderr e
```

Example 2: catch exception and stack backtrace, re-raise it later
--

The following relies on recording a stack backtrace using OCaml's
`Printexc` module. In this case, an exception catch-all captures the
stack trace as well and stores it with the exception.

```ocaml
let foo x =
  ...
  (* Raise (Failure "uh oh") normally *)
  failwith "uh oh"

let bar x =
  try Ok (foo x)
  with e ->
    (* Catch-all, records stack backtrace *)
    Error (Trax.wrap_with_stack_trace e)

let split_results (res_list : ('a, 'b) Result.t list): 'a list * 'b list =
  let ok, errors =
    List.fold_left (fun (ok, errors) res ->
      match res with
      | Ok x -> (x :: ok, errors)
      | Error x -> (ok, x :: errors)
    ) ([], []) res_list
  in
  List.rev ok, List.rev errors

let main () =
  Printexc.record_backtrace ();
  try
    ...
    let results = List.map bar jobs in
    let ok, errors = split_results results in
    (* Re-raise the first error, if any *)
    List.iter raise errors;
    ...
  with e ->
    (* Capture latest stack trace and append it to this exception's trace *)
    Trax.wrap_with_stack_trace e
    |> Trax.print stderr
```
