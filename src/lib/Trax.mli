(** The type of locations that make up the exception trace *)
type location = Text of string
              | Raw_backtrace of Printexc.raw_backtrace

(** Any exception and its trace *)
exception Traced of exn * location list

(** Add location to this exception's trace.
    If the input exception is not already wrapped, it gets wrapped into
    a [Traced] exception. If the original exception is already wrapped
    in a [Traced] exception, it gets unwrapped and rewrapped with
    the new, extended trace.

    Wrapping and unwrapping is not nested: calling
    [wrap loc (wrap loc e)] creates a single [Traced (e, ...)] node,
    not [Traced (Traced (e, ...), ...)].
*)
val wrap : location -> exn -> exn

(** Recover the original exception, for inspection purposes.
    For instance [Traced(Not_found, [...])] would become [Not_found]. *)
val unwrap : exn -> exn

(** Wrap an exception with the current exception backtrace
    (stack trace recorded at the point where
    the exception was raised, assuming no other exception was raised
    in-between). This is only guaranteed to work
    right after catching an exception with a try-with. *)
val wrap_with_stack_trace : exn -> exn

(** Raise or reraise an exception after adding a location to its trace. *)
val raise_at : location -> exn -> 'a

(** Raise or reraise an exception after adding a text location
    to its trace. Typical usage is [Trax.raise __LOC__ e]. *)
val raise : string -> exn -> 'a

(** Re-raise an exception after wrapping it with the current
    exception backtrace (stack trace recorded at the point where
    the exception was raised, assuming no other exception was raised
    in-between). This is only guaranteed to work
    right after catching an exception with a try-with. *)
val reraise_with_stack_trace : exn -> 'a

(** Convert a stack trace to readable lines. Duplicate lines are omitted
    and replaced by '...' or similar.

    This is a replacement for Printexc.raw_backtrace_to_string. *)
val raw_backtrace_to_string : Printexc.raw_backtrace -> string

(** Format the exception and its trace into text. *)
val to_string : exn -> string

(** Format the trace extracted from the exception into text. *)
val get_trace : exn -> string

(** Print the exception and its trace. *)
val print : out_channel -> exn -> unit
