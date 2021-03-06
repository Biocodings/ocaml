(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Pierre Weis, projet Cristal, INRIA Rocquencourt            *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Pretty-printing.

   This module implements a pretty-printing facility to format values
   within 'pretty-printing boxes'. The pretty-printer splits lines
   at specified break hints, and indents lines according to the box
   structure.

   For a gentle introduction to the basics of pretty-printing using
   [Format], read
   {{:http://caml.inria.fr/resources/doc/guides/format.en.html}
    http://caml.inria.fr/resources/doc/guides/format.en.html}.

   You may consider this module as providing an extension to the
   [printf] facility to provide automatic line splitting. The addition of
   pretty-printing annotations to your regular [printf] format strings gives
   you fancy indentation and line breaks.
   Pretty-printing annotations are described below in the documentation of
   the function {!Format.fprintf}.

   You may also use the explicit pretty-printing box management and printing
   functions provided by this module. This style is more basic but more
   verbose than the concise [fprintf] format strings.


   For instance, the sequence
   [open_box 0; print_string "x ="; print_space ();
    print_int 1; close_box (); print_newline ()]
   that prints [x = 1] within a pretty-printing box, can be
   abbreviated as [printf "@[%s@ %i@]@." "x =" 1], or even shorter
   [printf "@[x =@ %i@]@." 1].

   Rule of thumb for casual users of this library:
 - use simple pretty-printing boxes (as obtained by [open_box 0]);
 - use simple break hints as obtained by [print_cut ()] that outputs a
   simple break hint, or by [print_space ()] that outputs a space
   indicating a break hint;
 - once a pretty-printing box is open, display its material with basic
   printing functions (e. g. [print_int] and [print_string]);
 - when the material for a pretty-printing box has been printed, call
   [close_box ()] to close the box;
 - at the end of pretty-printing, flush the pretty-printer to display all
   the remaining material, e.g. evaluate [print_newline ()].

   The behavior of pretty-printing commands is unspecified
   if there is no open pretty-printing box. Each box open via
   one of the [open_] functions below must be closed using [close_box]
   for proper formatting. Otherwise, some of the material printed in the
   boxes may not be output, or may be formatted incorrectly.

   In case of interactive use, each phrase is executed in the initial state
   of the standard pretty-printer: after each phrase execution, the
   interactive system closes all open pretty-printing boxes, flushes all
   pending text, and resets the standard pretty-printer.

   Warning: mixing calls to pretty-printing functions of this module with
   calls to {!Pervasives} low level output functions is error prone.

   The pretty-printing functions output material that is delayed in the
   pretty-printer queue and stacks in order to compute proper line
   splitting. In contrast, basic I/O output functions write directely in
   their output device. As a consequence, the output of a basic I/O function
   may appear before the output of a pretty-printing function that has been
   called before. For instance,
   [
    Pervasives.print_string "<";
    Format.print_string "PRETTY";
    Pervasives.print_string ">";
    Format.print_string "TEXT";
   ]
   leads to output [<>PRETTYTEXT].

*)

(** {6 Pretty-printing boxes} *)

(** The pretty-printing engine uses the concepts of pretty-printing box and
  break hint to drive the indentation and the line splitting behavior of the
  pretty-printer.

  Each different pretty-printing box kind introduces a specific line splitting
  policy:

  - within an {e horizontal} box, break hints never split the line (but the
    line may be split in a box nested deeper),
  - within a {e vertical} box, break hints always split the line,
  - within an {e horizontal/vertical} box, if the box fits on the current line
    then break hints never split the line, otherwise break hint always split
    the line,
  - within an {e compacting} box, a break hint never splits the line,
    unless there is no more room on the current line.

  Note that line splitting policy is box specific: the policy of a box does
  not rule the policy of inner boxes. For instance, if a vertical box is
  nested in an horizontal box, all break hints within the vertical box will
  split the line.
*)

val open_box : int -> unit
(** [open_box d] opens a new compacting pretty-printing box with offset [d].

   Within this box, the pretty-printer prints as much as possible material on
   every line.

   A break hint splits the line if there is no more room on the line to
   print the remainder of the box.

   Within this box, the pretty-printer emphasizes the box structure: a break
   hint also splits the line if the splitting ``moves to the left''
   (i.e. the new line gets an indentation smaller than the one of the current
   line).

   This box is the general purpose pretty-printing box.

   If the pretty-printer splits the line in the box, offset [d] is added to
   the current indentation.
*)

val close_box : unit -> unit
(** Closes the most recently open pretty-printing box. *)

val open_hbox : unit -> unit
(** [open_hbox ()] opens a new 'horizontal' pretty-printing box.

  This box prints material on a single line.

  Break hints in a horizontal box never split the line.
  (Line splitting may still occur inside boxes nested deeper).
*)

val open_vbox : int -> unit
(** [open_vbox d] opens a new 'vertical' pretty-printing box
  with offset [d].

  This box prints material on as many lines as break hints in the box.

  Every break hint in a vertical box splits the line.

  If the pretty-printer splits the line in the box, [d] is added to the
  current indentation.
*)

val open_hvbox : int -> unit
(** [open_hvbox d] opens a new 'horizontal/vertical' pretty-printing box
  with offset [d].

  This box behaves as an horizontal box if it fits on a single line,
  otherwise it behaves as a vertical box.

  If the pretty-printer splits the line in the box, [d] is added to the
  current indentation.
*)

val open_hovbox : int -> unit
(** [open_hovbox d] opens a new 'horizontal-or-vertical' pretty-printing box
  with offset [d].

  This box prints material as much as possible on every line.

  A break hint splits the line if there is no more room on the line to
  print the remainder of the box.

  If the pretty-printer splits the line in the box, [d] is added to the
  current indentation.
*)

(** {6 Formatting functions} *)

val print_string : string -> unit
(** [print_string s] prints [s] in the current pretty-printing box. *)

val print_as : int -> string -> unit
(** [print_as len s] prints [s] in the current pretty-printing box.
  The pretty-printer formats [s] as if it were of length [len].
*)

val print_int : int -> unit
(** Print an integer in the current pretty-printing box. *)

val print_float : float -> unit
(** Print a floating point number in the current pretty-printing box. *)

val print_char : char -> unit
(** Print a character in the current pretty-printing box. *)

val print_bool : bool -> unit
(** Print a boolean in the current pretty-printing box. *)

(** {6 Break hints} *)

(** A 'break hint' tells the pretty-printer to output some space or split the
  line whichever way is more appropriate to the current pretty-printing box
  splitting rules.

  Break hints are used to separate printing items and are mandatory to let
  the pretty-printer correctly split lines and indent items.

  Simple break hints are:
  - the 'space': output a space or split the line if appropriate,
  - the 'cut': split the line if appropriate.

  Note: the notions of space and line splitting are abstract for the
  pretty-printing engine, since those notions can be completely redefined
  by the programmer.
  However, in the pretty-printer default setting, ``output a space'' simply
  means printing a space character (ASCII code 32) and ``split the line''
  means printing a newline character (ASCII code 10).
*)

val print_space : unit -> unit
(** [print_space ()] prints a 'space' break hint:
  the pretty-printer may split the line at this point,
  otherwise it prints one space.

  [print_space] is equivalent to [print_break 1 0].
*)

val print_cut : unit -> unit
(** [print_cut ()] prints a 'cut' break hint:
  the pretty-printer may split the line at this point,
  otherwise it prints nothing.

  [print_cut] is equivalent to [print_break 0 0].
*)

val print_break : int -> int -> unit
(** [print_break nspaces offset] prints a 'full' break hint:
  the pretty-printer may split the line at this point,
  otherwise it prints [nspaces] spaces.

  If the pretty-printer splits the line, [offset] is added to
  the current indentation.
*)

val force_newline : unit -> unit
(** Force a new line in the current pretty-printing box.

  The pretty-printer must split the line at this point,

  Not the normal way of pretty-printing, since imperative line splitting may
  interfere with current line counters and box size calculation.
  Using break hints within an enclosing vertical box is a better
  alternative.

*)

val print_if_newline : unit -> unit
(** Execute the next formatting command if the preceding line
  has just been split. Otherwise, ignore the next formatting
  command.
*)

(** {6 Pretty-printing termination} *)

val print_flush : unit -> unit
(** End of pretty-printing: resets the pretty-printer to initial state.

  All open pretty-printing boxes are closed, all pending text is printed.
  In addition, the pretty-printer low level output device is flushed to
  ensure that all pending text is really displayed.

  Note: never use [print_flush] in the normal course of a pretty-printing
  routine, since the pretty-printer uses a complex buffering machinery to
  properly indent the output; manually flushing those buffers at random
  would conflict with the pretty-printer strategy and result to poor
  rendering.

  Only consider using [print_flush] when displaying all pending material is
  mandatory (for instance in case of interactive use when you want the user
  to read some text) and when resetting the pretty-printer state will not
  disturb further pretty-printing.

  Warning: If the output device of the pretty-printer is an output channel,
  repeated calls to [print_flush] means repeated calls to {!Pervasives.flush}
  to flush the out channel; these explicit flush calls could foil the
  buffering strategy of output channels and could dramatically impact
  efficiency.

*)

val print_newline : unit -> unit
(** End of pretty-printing: resets the pretty-printer to initial state.

  All open pretty-printing boxes are closed, all pending text is printed.

  Equivalent to {!print_flush} followed by a new line.
  See corresponding words of caution for {!print_flush}.

  Note: this is not the normal way to output a new line;
  the preferred method is using break hints within a vertical pretty-printing
  box.
*)

(** {6 Margin} *)

val set_margin : int -> unit
(** [set_margin d] sets the right margin to [d] (in characters):
  the pretty-printer splits lines that overflow the right margin according to
  the break hints given.
  Nothing happens if [d] is smaller than 2.
  If [d] is too large, the right margin is set to the maximum
  admissible value (which is greater than [10 ^ 9]).
*)

val get_margin : unit -> int
(** Returns the position of the right margin. *)

(** {6 Maximum indentation limit} *)

val set_max_indent : int -> unit
(** [set_max_indent d] sets the maximum indentation limit of lines to [d] (in
  characters):
  once this limit is reached, new pretty-printing boxes are rejected to the left,
  if they do not fit on the current line.
  Nothing happens if [d] is smaller than 2.
  If [d] is too large, the limit is set to the maximum
  admissible value (which is greater than [10 ^ 9]).
*)

val get_max_indent : unit -> int
(** Return the maximum indentation limit (in characters). *)

(** {6 Maximum formatting depth} *)

(** The maximum formatting depth is the maximum allowed number of
  simultaneously open pretty-printing boxes before ellipsis. *)

val set_max_boxes : int -> unit
(** [set_max_boxes max] sets the maximum number of pretty-printing boxes
  simultaneously open.

  Material inside boxes nested deeper is printed as an ellipsis (more
  precisely as the text returned by [get_ellipsis_text ()]).
  Nothing happens if [max] is smaller than 2.
*)

val get_max_boxes : unit -> int
(** Returns the maximum number of pretty-printing boxes allowed before
  ellipsis.
*)

val over_max_boxes : unit -> bool
(** Tests if the maximum number of pretty-printing boxes allowed have already
  been open.
*)

(** {6 Ellipsis} *)

val set_ellipsis_text : string -> unit
(** Set the text of the ellipsis printed when too many pretty-printing boxes
  are open (a single dot, [.], by default).
*)

val get_ellipsis_text : unit -> string
(** Return the text of the ellipsis. *)

(** {6:tags Semantic tags} *)

type tag = string

(** {i Semantic tags} (or simply {e tags}) are user's defined delimiters
  to associate user's specific operations to printed entities.

  Common usage of semantic tags is text decoration to get specific font or
  text size rendering for a display device, or marking delimitation of
  entities (e.g. HTML or TeX elements or terminal escape sequences).
  More sophisticated usage of semantic tags could handle dynamic
  modification of the pretty-printer behavior to properly print the material
  within some specific tags.

  In order to properly delimit printed entities, a semantic tag must be
  opened before and closed after the entity. Semantic tags must be properly
  nested like parentheses.

  Tag specific operations occur any time a tag is opened or closed, At each
  occurrence, two kinds of operations are performed {e tag-marking} and
  {e tag-printing}:
- The tag-marking operation is the simpler tag specific operation: it simply
  writes a tag specific string into the output device of the
  formatter. Tag-marking does not interfere with line-splitting computation.
- The tag-printing operation is the more involved tag specific operation: it
  can print arbitrary material to the formatter. Tag-printing is tightly
  linked to the current pretty-printer operations.

  Roughly speaking, tag-marking is commonly used to get a better rendering of
  texts in the rendering device, while tag-printing allows fine tuning of
  printing routines to print the same entity differently according to the
  semantic tags (i.e. print additional material or even omit parts of the
  output).

  More precisely: when a semantic tag is opened or closed then both and
  successive 'tag-printing' and 'tag-marking' operations occur:
  - Tag-printing a semantic tag means calling the formatter specific function
  [print_open_tag] (resp. [print_close_tag]) with the name of the tag as
  argument: that tag-printing function can then print any regular material
  to the formatter (so that this material is enqueued as usual in the
  formatter queue for further line splitting computation).
  - Tag-marking a semantic tag means calling the formatter specific function
  [mark_open_tag] (resp. [mark_close_tag]) with the name of the tag as
  argument: that tag-marking function can then return the 'tag-opening
  marker' (resp. `tag-closing marker') for direct output into the output
  device of the formatter.

  Being written directly into the output device of the formatter, semantic
  tag marker strings are not considered as part of the printing material that
  drives line splitting (in other words, the length of the strings
  corresponding to tag markers is considered as zero for line splitting).

  Thus, semantic tag handling is in some sense transparent to pretty-printing
  and does not interfere with usual indentation. Hence, a single
  pretty-printing routine can output both simple 'verbatim' material or
  richer decorated output depending on the treatment of tags. By default,
  tags are not active, hence the output is not decorated with tag
  information. Once [set_tags] is set to [true], the pretty-printer engine
  honors tags and decorates the output accordingly.

  Default tag-marking functions behave the HTML way: tags are enclosed in "<"
  and ">"; hence, opening marker for tag [t] is ["<t>"] and closing marker is
  ["</t>"].

  Default tag-printing functions just do nothing.

  Tag-marking and tag-printing functions are user definable and can
  be set by calling {!set_formatter_tag_functions}.

  Semantic tag operations may be set on or off with {!set_tags}.
  Tag-marking operations may be set on or off with {!set_mark_tags}.
  Tag-printing operations may be set on or off with {!set_print_tags}.
*)

val open_tag : tag -> unit
(** [open_tag t] opens the semantic tag named [t].

  The [print_open_tag] tag-printing function of the formatter is called with
  [t] as argument; then the opening tag marker, as given by [mark_open_tag t]
  is written into the output device of the formatter.
*)

val close_tag : unit -> unit
(** [close_tag ()] closes the most recently opened semantic tag [t].

  The closing tag marker, as given by [mark_close_tag t], is written into the
  output device of the formatter; then the [print_close_tag] tag-printing
  function of the formatter is called with [t] as argument.
*)

val set_tags : bool -> unit
(** [set_tags b] turns on or off the treatment of semantic tags
  (default is off). *)

val set_print_tags : bool -> unit
(** [set_print_tags b] turns on or off the tag-printing operations. *)

val set_mark_tags : bool -> unit
(** [set_mark_tags b] turns on or off the tag-marking operation. *)

val get_print_tags : unit -> bool
(** Return the current status of tag-printing operations. *)

val get_mark_tags : unit -> bool
(** Return the current status of tag-marking operations. *)

(** {6 Redirecting the standard formatter output} *)

val set_formatter_out_channel : Pervasives.out_channel -> unit
(** Redirect the standard pretty-printer output to the given channel.
  (All the output functions of the standard formatter are set to the
   default output functions printing to the given channel.)
  [set_formatter_out_channel] is equivalent to
  [pp_set_formatter_out_channel std_formatter].
*)

val set_formatter_output_functions :
  (string -> int -> int -> unit) -> (unit -> unit) -> unit
(** [set_formatter_output_functions out flush] redirects the
  standard pretty-printer output functions to the functions [out] and
  [flush].

  The [out] function performs all the pretty-printer string output.
  It is called with a string [s], a start position [p], and a number of
  characters [n]; it is supposed to output characters [p] to [p + n - 1] of
  [s].

  The [flush] function is called whenever the pretty-printer is flushed
  (via conversion [%!], or pretty-printing indications [@?] or [@.], or
  using low level functions [print_flush] or [print_newline]).
*)

val get_formatter_output_functions :
  unit -> (string -> int -> int -> unit) * (unit -> unit)
(** Return the current output functions of the standard pretty-printer. *)

(** {6:meaning Redefining formatter output} *)

(** The [Format] module is versatile enough to let you completely redefine
  the meaning of pretty-printing output: you may provide your own functions
  to define how to handle indentation, line splitting, and even printing of
  all the characters that have to be printed!
*)

(** {7 Redefining output functions} *)

type formatter_out_functions = {
  out_string : string -> int -> int -> unit;
  out_flush : unit -> unit;
  out_newline : unit -> unit;
  out_spaces : int -> unit;
  out_indent : int -> unit;
}
(** The set of output functions specific to a formatter:
- the [out_string] function performs all the pretty-printer string output.
  It is called with a string [s], a start position [p], and a number of
  characters [n]; it is supposed to output characters [p] to [p + n - 1] of
  [s].
- the [out_flush] function flushes the pretty-printer output device.
- [out_newline] is called to open a new line when the pretty-printer splits
  the line.
- the [out_spaces] function outputs spaces when a break hint leads to spaces
  instead of a line split. It is called with the number of spaces to output.
- the [out_indent] function performs new line indentation when the
  pretty-printer splits the line. It is called with the indentation value of
  the new line.

  By default:
- fields [out_string] and [out_flush] are output device specific;
  (e.g. [!Pervasives.output_string] and [!Pervasives.flush] for a
   [!Pervasives.out_channel] device, or [Buffer.add_substring] and
   [!Pervasives.ignore] for a [Buffer.t] output device),
- field [out_newline] is equivalent to [out_string "\n" 0 1];
- field [out_spaces] is equivalent to [out_string (String.make n ' ') 0 n];
- field [out_indent] is the same as field [out_spaces].
*)


val set_formatter_out_functions : formatter_out_functions -> unit
(** [set_formatter_out_functions out_funs]
  Set all the pretty-printer output functions to those of argument
  [out_funs],

  This way, you can change the meaning of indentation (which can be
  something else than just printing space characters) and the meaning of new
  lines opening (which can be connected to any other action needed by the
  application at hand).
*)


val get_formatter_out_functions : unit -> formatter_out_functions
(** Return the current output functions of the pretty-printer,
  including line splitting and indentation functions. Useful to record the
  current setting and restore it afterwards.
  @since 4.01.0 *)


(** {6:tagsmeaning Redefining semantic tags operations} *)

type formatter_tag_functions = {
  mark_open_tag : tag -> string;
  mark_close_tag : tag -> string;
  print_open_tag : tag -> unit;
  print_close_tag : tag -> unit;
}
(** The semantic tag handling functions specific to a formatter:
  [mark] versions are the 'tag-marking' functions that associate a string
  marker to a tag in order for the pretty-printing engine to write
  those markers as 0 length tokens in the output device of the formatter.
  [print] versions are the 'tag-printing' functions that can perform
  regular printing when a tag is closed or opened.
*)

val set_formatter_tag_functions : formatter_tag_functions -> unit
(** [set_formatter_tag_functions tag_funs] changes the meaning of
  opening and closing semantic tag operations to use the functions in
  [tag_funs].

  When opening a semantic tag name [t], the string [t] is passed to the
  opening tag-marking function (the [mark_open_tag] field of the
  record [tag_funs]), that must return the opening tag marker for
  that name. When the next call to [close_tag ()] happens, the semantic tag
  name [t] is sent back to the closing tag-marking function (the
  [mark_close_tag] field of record [tag_funs]), that must return a
  closing tag marker for that name.

  The [print_] field of the record contains the tag-printing functions that
  are called at tag opening and tag closing time, to output regular material
  in the pretty-printer queue.
*)

val get_formatter_tag_functions : unit -> formatter_tag_functions
(** Return the current semantic tag operation functions of the standard
  pretty-printer. *)

(** {6 Defining formatters} *)

type formatter
(** Abstract data corresponding to a pretty-printer (also called a
  formatter) and all its machinery.

  Defining new formatters permits unrelated output of material in
  parallel on several output devices.
  All the parameters of a formatter are local to the formatter:
  right margin, maximum indentation limit, maximum number of pretty-printing
  boxes simultaneously open, ellipsis, and so on, are specific to
  each formatter and may be fixed independently.

  For instance, given a [!Buffer.t] buffer [b], [formatter_of_buffer b]
  returns a new formatter using buffer [b] as its output device.
  Similarly, given a [!Pervasives.out_channel] output channel [oc],
  [formatter_of_out_channel oc] returns a new formatter using
  channel [oc] as its output device.

  Alternatively, given [out_funs], a complete set of output functions for a
  formatter, then {!formatter_of_out_function out_funs} computes a new
  formatter using those functions for output.

*)

val formatter_of_out_channel : out_channel -> formatter
(** [formatter_of_out_channel oc] returns a new formatter writing
  to the corresponding channel [oc].
*)

val std_formatter : formatter
(** The standard formatter to write to standard output.

  It is defined as [formatter_of_out_channel stdout].
*)

val err_formatter : formatter
(** A formatter to to write to standard error.

  It is defined as [formatter_of_out_channel stderr].
*)

val formatter_of_buffer : Buffer.t -> formatter
(** [formatter_of_buffer b] returns a new formatter writing to
  buffer [b]. At the end of pretty-printing, the formatter must be flushed
  using [pp_print_flush] or [pp_print_newline], to print all the pending
  material into the buffer.
*)

val stdbuf : Buffer.t
(** The string buffer in which [str_formatter] writes. *)

val str_formatter : formatter
(** A formatter to output to the [stdbuf] string buffer.

  [str_formatter] is defined as [formatter_of_buffer stdbuf].
*)

val flush_str_formatter : unit -> string
(** Returns the material printed with [str_formatter], flushes
  the formatter and resets the corresponding buffer.
*)

val make_formatter :
  (string -> int -> int -> unit) -> (unit -> unit) -> formatter
(** [make_formatter out flush] returns a new formatter that outputs with
  function [out], and flushes with function [flush].

  For instance, a formatter to the [!Pervasives.out_channel] [oc] is returned
  by [make_formatter (!Pervasives.output oc) (fun () -> !Pervasives.flush
  oc)].
*)

val formatter_of_out_functions :
  formatter_out_functions -> formatter
(** [formatter_of_out_functions out_funs] returns a new formatter that writes
    with the set of output functions [out_funs].

  See definition of type {!formatter_out_functions} for the meaning of argument
  [out_funs].

  @since 4.04.0
*)


(** {7 Symbolic pretty-printing} *)

(**
  Symbolic pretty-printing is pretty-printing with no low level output.

  When using a symbolic formatter, all regular pretty-printing activities
  occur but output material is symbolic and stored in a buffer of output items.
  At the end of pretty-printing, flushing the output buffer allows
  post-processing of symbolic output before low level output operations.
*)

type symbolic_output_item =
  | Output_flush
  | Output_newline
  | Output_string of string
  | Output_spaces of int
  | Output_indent of int
(**
  The output items that symbolic pretty-printers will produce:
  - [Output_flush]: symbolic flush command.
  - [Output_newline]: symbolic newline command.
  - [Output_string s]: symbolic output for string [s].
  - [Output_spaces n]: symbolic command to output [n] spaces.
  - [Output_indent i]: symbolic indentation of size [i].

  @since 4.04.0
*)

type symbolic_output_buffer
(**
  The output buffer of a symbolic pretty-printer.

  @since 4.04.0
*)

val make_symbolic_output_buffer : unit -> symbolic_output_buffer
(** [make_symbolic_output_buffer ()] returns a fresh buffer for
  symbolic output.

  @since 4.04.0
*)

val clear_symbolic_output_buffer : symbolic_output_buffer -> unit
(** [clear_symbolic_output_buffer sob] resets buffer [sob].

  @since 4.04.0
*)

val get_symbolic_output_buffer :
  symbolic_output_buffer -> symbolic_output_item list
(** [get_symbolic_output_buffer sob] returns the contents of buffer [sob].

  @since 4.04.0
*)

val flush_symbolic_output_buffer :
  symbolic_output_buffer -> symbolic_output_item list
(** [flush_symbolic_output_buffer sob] returns the contents of buffer
  [sob] and resets buffer [sob].
  [flush_symbolic_output_buffer sob] is equivalent to
  [let items = get_symbolic_output_buffer sob in
   clear_symbolic_output_buffer sob; items]

  @since 4.04.0
*)

val add_symbolic_output_item :
  symbolic_output_buffer -> symbolic_output_item -> unit
(** [add_symbolic_output_item sob itm] adds item [itm] to buffer [sob].
*)

val formatter_of_symbolic_output_buffer : symbolic_output_buffer -> formatter
(** [formatter_of_symbolic_output_buffer sob] returns a symbolic formatter
  that outputs to [symbolic_output_buffer] [sob].

  @since 4.04.0
*)

(** {6 Basic functions for formatters} *)

val pp_open_hbox : formatter -> unit -> unit
val pp_open_vbox : formatter -> int -> unit
val pp_open_hvbox : formatter -> int -> unit
val pp_open_hovbox : formatter -> int -> unit
val pp_open_box : formatter -> int -> unit
val pp_close_box : formatter -> unit -> unit
val pp_open_tag : formatter -> string -> unit
val pp_close_tag : formatter -> unit -> unit
val pp_print_string : formatter -> string -> unit
val pp_print_as : formatter -> int -> string -> unit
val pp_print_int : formatter -> int -> unit
val pp_print_float : formatter -> float -> unit
val pp_print_char : formatter -> char -> unit
val pp_print_bool : formatter -> bool -> unit
val pp_print_break : formatter -> int -> int -> unit
val pp_print_cut : formatter -> unit -> unit
val pp_print_space : formatter -> unit -> unit
val pp_force_newline : formatter -> unit -> unit
val pp_print_flush : formatter -> unit -> unit
val pp_print_newline : formatter -> unit -> unit
val pp_print_if_newline : formatter -> unit -> unit
val pp_set_tags : formatter -> bool -> unit
val pp_set_print_tags : formatter -> bool -> unit
val pp_set_mark_tags : formatter -> bool -> unit
val pp_get_print_tags : formatter -> unit -> bool
val pp_get_mark_tags : formatter -> unit -> bool
val pp_set_margin : formatter -> int -> unit
val pp_get_margin : formatter -> unit -> int
val pp_set_max_indent : formatter -> int -> unit
val pp_get_max_indent : formatter -> unit -> int
val pp_set_max_boxes : formatter -> int -> unit
val pp_get_max_boxes : formatter -> unit -> int
val pp_over_max_boxes : formatter -> unit -> bool
val pp_set_ellipsis_text : formatter -> string -> unit
val pp_get_ellipsis_text : formatter -> unit -> string
val pp_set_formatter_out_channel :
  formatter -> Pervasives.out_channel -> unit

val pp_set_formatter_output_functions :
  formatter -> (string -> int -> int -> unit) -> (unit -> unit) -> unit

val pp_get_formatter_output_functions :
  formatter -> unit -> (string -> int -> int -> unit) * (unit -> unit)

val pp_set_formatter_tag_functions :
  formatter -> formatter_tag_functions -> unit

val pp_get_formatter_tag_functions :
  formatter -> unit -> formatter_tag_functions

val pp_set_formatter_out_functions :
  formatter -> formatter_out_functions -> unit
(** @since 4.01.0 *)

val pp_get_formatter_out_functions :
  formatter -> unit -> formatter_out_functions


(** These functions are the basic ones: usual functions
  operating on the standard formatter are defined via partial
  evaluation of these primitives. For instance,
  [print_string] is equal to [pp_print_string std_formatter].
*)


(** {6 Convenience formatting functions.} *)

val pp_print_list:
  ?pp_sep:(formatter -> unit -> unit) ->
  (formatter -> 'a -> unit) -> (formatter -> 'a list -> unit)
(** [pp_print_list ?pp_sep pp_v ppf l] prints items of list [l],
  using [pp_v] to print each item, and calling [pp_sep]
  between items ([pp_sep] defaults to {!pp_print_cut}).
  Does nothing on empty lists.

  @since 4.02.0
*)

val pp_print_text : formatter -> string -> unit
(** [pp_print_text ppf s] prints [s] with spaces and newlines respectively
  printed using {!pp_print_space} and {!pp_force_newline}.

  @since 4.02.0
*)

(** {6 Formatted pretty-printing} *)

(**
  Module [Format] provides a complete set of [printf] like functions for
  pretty-printing using format string specifications.

  Specific annotations may be added in the format strings to give
  pretty-printing commands to the pretty-printing engine.

  Those annotations are introduced in the format strings using the [@]
  character. For instance, [@ ] means a space break, [@,] means a cut,
  [@\[] opens a new box, and [@\]] closes the last open box.

*)

val fprintf : formatter -> ('a, formatter, unit) format -> 'a

(** [fprintf ff fmt arg1 ... argN] formats the arguments [arg1] to [argN]
  according to the format string [fmt], and outputs the resulting string on
  the formatter [ff].

  The format string [fmt] is a character string which contains three types of
  objects: plain characters and conversion specifications as specified in
  the {!Printf} module, and pretty-printing indications specific to the
  [Format] module.

  The pretty-printing indication characters are introduced by
  a [@] character, and their meanings are:
  - [@\[]: open a pretty-printing box. The type and offset of the
    box may be optionally specified with the following syntax:
    the [<] character, followed by an optional box type indication,
    then an optional integer offset, and the closing [>] character.
    Pretty-printing box type is one of [h], [v], [hv], [b], or [hov].
    '[h]' stands for an 'horizontal' pretty-printing box,
    '[v]' stands for a 'vertical' pretty-printing box,
    '[hv]' stands for an 'horizontal/vertical' pretty-printing box,
    '[b]' stands for an 'horizontal-or-vertical' pretty-printing box
    demonstrating indentation,
    '[hov]' stands a simple 'horizontal-or-vertical' pretty-printing box.
    For instance, [@\[<hov 2>] opens an 'horizontal-or-vertical'
    pretty-printing box with indentation 2 as obtained with [open_hovbox 2].
    For more details about pretty-printing boxes, see the various box opening
    functions [open_*box].
  - [@\]]: close the most recently opened pretty-printing box.
  - [@,]: output a 'cut' break hint, as with [print_cut ()].
  - [@ ]: output a 'space' break hint, as with [print_space ()].
  - [@;]: output a 'full' break hint as with [print_break]. The
    [nspaces] and [offset] parameters of the break hint may be
    optionally specified with the following syntax:
    the [<] character, followed by an integer [nspaces] value,
    then an integer [offset], and a closing [>] character.
    If no parameters are provided, the good break defaults to a
    'space' break hint.
  - [@.]: flush the pretty-printer and split the line, as with
    [print_newline ()].
  - [@<n>]: print the following item as if it were of length [n].
    Hence, [printf "@<0>%s" arg] prints [arg] as a zero length string.
    If [@<n>] is not followed by a conversion specification,
    then the following character of the format is printed as if
    it were of length [n].
  - [@\{]: open a semantic tag. The name of the tag may be optionally
    specified with the following syntax:
    the [<] character, followed by an optional string
    specification, and the closing [>] character. The string
    specification is any character string that does not contain the
    closing character ['>']. If omitted, the tag name defaults to the
    empty string.
    For more details about semantic tags, see the functions [{!open_tag}] and
    [{!close_tag}].
  - [@\}]: close the most recently opened semantic tag.
  - [@?]: flush the pretty-printer as with [print_flush ()].
    This is equivalent to the conversion [%!].
  - [@\n]: force a newline, as with [force_newline ()], not the normal way
    of pretty-printing, you should prefer using break hints inside a vertical
    pretty-printing box.

  Note: To prevent the interpretation of a [@] character as a
  pretty-printing indication, escape it with a [%] character.
  Old quotation mode [@@] is deprecated since it is not compatible with
  formatted input interpretation of character ['@'].

  Example: [printf "@[%s@ %d@]@." "x =" 1] is equivalent to
  [open_box (); print_string "x ="; print_space ();
   print_int 1; close_box (); print_newline ()].
  It prints [x = 1] within a pretty-printing 'horizontal-or-vertical' box.

*)

val printf : ('a, formatter, unit) format -> 'a
(** Same as [fprintf] above, but output on [std_formatter]. *)

val eprintf : ('a, formatter, unit) format -> 'a
(** Same as [fprintf] above, but output on [err_formatter]. *)

val sprintf : ('a, unit, string) format -> 'a
(** Same as [printf] above, but instead of printing on a formatter,
  returns a string containing the result of formatting the arguments.
  Note that the pretty-printer queue is flushed at the end of {e each
  call} to [sprintf].

  In case of multiple and related calls to [sprintf] to output
  material on a single string, you should consider using [fprintf]
  with the predefined formatter [str_formatter] and call
  [flush_str_formatter ()] to get the final result.

  Alternatively, you can use [Format.fprintf] with a formatter writing to a
  buffer of your own: flushing the formatter and the buffer at the end of
  pretty-printing returns the desired string.
*)

val asprintf : ('a, formatter, unit, string) format4 -> 'a
(** Same as [printf] above, but instead of printing on a formatter,
  returns a string containing the result of formatting the arguments.
  The type of [asprintf] is general enough to interact nicely with [%a]
  conversions.

  @since 4.01.0
*)

val ifprintf : formatter -> ('a, formatter, unit) format -> 'a
(** Same as [fprintf] above, but does not print anything.
  Useful to ignore some material when conditionally printing.

  @since 3.10.0
*)

(** Formatted Pretty-Printing with continuations. *)

val kfprintf :
  (formatter -> 'a) -> formatter ->
  ('b, formatter, unit, 'a) format4 -> 'b
(** Same as [fprintf] above, but instead of returning immediately,
  passes the formatter to its first argument at the end of printing. *)

val ikfprintf :
  (formatter -> 'a) -> formatter ->
  ('b, formatter, unit, 'a) format4 -> 'b
(** Same as [kfprintf] above, but does not print anything.
  Useful to ignore some material when conditionally printing.

  @since 3.12.0
*)

val ksprintf : (string -> 'a) -> ('b, unit, string, 'a) format4 -> 'b
(** Same as [sprintf] above, but instead of returning the string,
  passes it to the first argument. *)

val kasprintf : (string -> 'a) -> ('b, formatter, unit, 'a) format4 -> 'b
(** Same as [asprintf] above, but instead of returning the string,
  passes it to the first argument.

  @since 4.03
*)

(** {6 Deprecated} *)

val bprintf : Buffer.t -> ('a, formatter, unit) format -> 'a
  [@@ocaml.deprecated]
(** @deprecated This function is error prone. Do not use it.
  This function is neither compositional nor incremental, since it flushes
  the pretty-printer queue at each call.

  If you need to print to some buffer [b], you must first define a
  formatter writing to [b], using [let to_b = formatter_of_buffer b]; then
  use regular calls to [Format.fprintf] with formatter [to_b].
*)

val kprintf : (string -> 'a) -> ('b, unit, string, 'a) format4 -> 'b
  [@@ocaml.deprecated "Use Format.ksprintf instead."]
(** @deprecated An alias for [ksprintf]. *)

val set_all_formatter_output_functions :
  out:(string -> int -> int -> unit) ->
  flush:(unit -> unit) ->
  newline:(unit -> unit) ->
  spaces:(int -> unit) ->
  unit
[@@ocaml.deprecated "Use Format.set_formatter_out_functions instead."]
(** @deprecated Subsumed by [set_formatter_out_functions]. *)

val get_all_formatter_output_functions :
  unit ->
  (string -> int -> int -> unit) *
  (unit -> unit) *
  (unit -> unit) *
  (int -> unit)
[@@ocaml.deprecated "Use Format.get_formatter_out_functions instead."]
(** @deprecated Subsumed by [get_formatter_out_functions]. *)

val pp_set_all_formatter_output_functions :
  formatter -> out:(string -> int -> int -> unit) -> flush:(unit -> unit) ->
  newline:(unit -> unit) -> spaces:(int -> unit) -> unit
[@@ocaml.deprecated "Use Format.pp_set_formatter_out_functions instead."]
(** @deprecated Subsumed by [pp_set_formatter_out_functions]. *)

val pp_get_all_formatter_output_functions :
  formatter -> unit ->
  (string -> int -> int -> unit) * (unit -> unit) * (unit -> unit) *
  (int -> unit)
[@@ocaml.deprecated "Use Format.pp_get_formatter_out_functions instead."]
(** @deprecated Subsumed by [pp_get_formatter_out_functions]. *)

(** Tabulation pretty-printing boxes are deprecated. *)

val pp_open_tbox : formatter -> unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val pp_close_tbox : formatter -> unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val pp_print_tbreak : formatter -> int -> int -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val pp_set_tab : formatter -> unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val pp_print_tab : formatter -> unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val open_tbox : unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val close_tbox : unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val print_tbreak : int -> int -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val set_tab : unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)

val print_tab : unit -> unit
[@@ocaml.deprecated "Tabulation pretty-printing boxes are not supported any more."]
(** @deprecated since 4.03.0 *)
