//// The module containing the functions for building the `Formatter`, and for using a
//// `Formatter(a)` to transform `List(a)` into a `String`, which can be directly written to file.
//// 
//// ## Examples
//// A basic example of formatting data
//// ```gleam
//// import gleam/int
//// import mesv/format
//// 
//// const data: List(#(String, Int, Bool)) = [
////   #("Adam", 20, True),
////   #("Beatrice", 25, True),
////   #("Colin", 2, False),
//// ]
//// 
//// pub fn main() -> Nil {
////   let formatter =
////     // First create a formatter
////     format.build(fn(val: #(String, Int, Bool)) -> List(String) {
////       let #(name, age, adult) = val
////       [
////         name,
////         int.to_string(age),
////         case adult {
////           True -> "true"
////           False -> "false"
////         },
////       ]
////     })
//// 
////   // Then, use that formatter on the data you want to format
////   let formatted_data = format.format(formatter, data)
//// 
////   // By default, the formatter uses the comma as a column separator,
////   // newline as the row separator, and doublequotes for escaping cells
////   assert formatted_data == "Adam,20,true\nBeatrice,25,true\nColin,2,false"
//// }
//// ```
//// A cool party trick to impress your friends - computing data *just in time*
//// when converting to string, minimizing the memory required!
//// ```gleam
//// // [...]
//// const data: List(#(String, Int)) = [
////   #("Alex", 20),
////   #("Betty", 25),
////   #("Conrad", 2),
//// ]
//// 
//// pub fn main() -> Nil {
////   let formatted_data =
////     format.build(fn(val: #(String, Int)) -> List(String) {
////       let #(name, age) = val
////       [
////         name,
////         int.to_string(age),
////         bool.to_string(age >= 18),
////       ]
////     })
////     |> format.format(data)
//// 
////   assert formatted_data == "Alex,20,True\nBetty,25,True\nConrad,2,False"
//// }
//// ```
//// 

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import mesv/util

// ==== Public Types ====

/// The type describing how to convert a specified data type `a` into String form.
/// 
/// To create it, use the [`format.build`](format.html#build) function and the provided transformation functions (`set_row_sep`, `set_col_sep`, `set_headers`, `set_escaper`) to configure the specific behaviour.
/// 
/// Once you have the required `Formatter(a)`, use the [`format.run`](format.html#run) function to convert a `List(a)` into a String.
/// 
pub opaque type Formatter(a) {
  Formatter(
    column_separator: String,
    row_separator: String,
    escaper: String,
    metadata_separator: String,
    escape_all: Bool,
    column_data: #(RowWhitespaceBehaviour, Option(List(String))),
    formatter: fn(a) -> List(String),
  )
}

/// Type specifying how to deal with the whitespace of cells in a specific column
/// (whitespace **around** the value, not inside).
/// 
/// By default, the `Formatter` is initialized with the `DoNothing` variant.
/// 
/// ## Note
/// The transformations described by this type occur after a value representing
/// a single row has been transformed into a `List(String)` of individual cells,
/// but before they were escaped (escapers duplicated and wrapped if required).
/// 
/// ## Another note
/// You might notice there is no option to pad all cells to the width of the widest
/// value in a column. This is because this library is aimed at eventually allowing
/// fully streamlined parsing and formatting of huge CSV files, which are never
/// all in the program's memory. 
/// 
/// To implement a feature like that, there would need to be *two* passes when
/// formatting - first to find the longest values in each column, then another
/// to actually parse them.
/// 
/// I am of the opinion that the benefits such a feature would bring do not outweigh
/// the complexity necessary to implement it, and so have decided not to provide it.
/// 
pub type ColumnWhitespaceBehaviour {
  /// As said, do nothing with the whitespace surrounding a cell;
  /// Pass the `String` along as is.
  /// 
  DoNothing
  /// Trim both sides of the formatted value before passing it along.
  /// 
  TrimAll
  /// Trim only the start of the formatted value, so that the column is Left aligned.
  /// 
  /// Of course, that'sassuming all of the previous columns were same width.
  /// 
  TrimStart
  /// Trim both ends of the formatted value, then pad the right to be at least the specified width.
  /// 
  /// ## **Important!**
  /// If the `String` is longer than the specified width, nothing happens;
  /// None of the contents are deleted.
  /// 
  /// If you wish to ensure that a column is fully aligned, you must manually create
  /// a column formatter that cuts off excess characters - such a feature is not,
  /// and will not be provided by this library.
  /// 
  LeftAlignPad(to: Int)
  /// Trim both ends of the formatted value, then pad the left make the cell be
  /// at least the specified width.
  /// 
  /// ## **Important!**
  /// If the `String` is longer than the specified width, nothing happens;
  /// None of the contents are deleted.
  /// 
  /// If you wish to ensure that a column is fully aligned, you must manually create
  /// a column formatter that cuts off excess characters - such a feature is not,
  /// and will not be provided by this library.
  /// 
  RightAlignPad(to: Int)
}

/// Type specifying the whitespace formatting behaviour of the entire row.
/// 
pub type RowWhitespaceBehaviour {
  /// When specifying this variant, all of the cells in a single row use the exact same
  /// `ColumnWhitespaceBehaviour`, with the exact same values if the variant chosen is
  /// `LeftAlignPad` or `RightAlignPad`.
  /// 
  /// This is also the default starting value of a new `Formatter` -
  /// `ExactSameForAllColumns(DoNothing)`.
  /// 
  ExactSameForAllColumns(ColumnWhitespaceBehaviour)
  /// When specifying this variant, the columns use the specified column behaviour in order,
  /// and if it occurs that the list in this variant is shorter than the `List(String)`
  /// for a given row, then the rest of the cells in that row default to the `DoNothing` variant.
  /// 
  SpecifiedForStartingColumns(List(ColumnWhitespaceBehaviour))
}

// ==== Private Types ====

type EscapeWhich {
  Metadata
  Data
}

// ==== Public API ====

// => Builder Functions

/// Function for directly building a `Formatter` that outputs the specified
/// elements in an exact order.
/// 
/// ## Example
/// The simplest formatter - converts a single `String` into a single element `List(String)`.
/// ```gleam
/// format.build(fn(val: String) -> List(String) { [val] })
/// ```
/// For more complicated data types, such as `Lists`, you need to create your own
/// formatting and parsing schema.
/// ```gleam
/// format.build(fn(val: #(String, List(Int))) -> List(String) {
///   let ints =
///     val.1
///     |> list.map(int.to_string)
///     |> string.join(",")
///   [
///     val.0,
///     "[" <> ints <> "]"
///   ]
/// })
///   |> format.run([#("test", [1, 3, 2])])
///   // -> "test,\"[1,3,2]\""
/// ```
/// Keep in mind that for such complex data types, it's up to you, as the user, to ensure
/// that every possible input to your formatting function can be losslessly parsed with
/// the corresponding parsing function.
/// 
pub fn build(format_row: fn(a) -> List(String)) -> Formatter(a) {
  Formatter(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    metadata_separator: ":",
    escape_all: False,
    column_data: #(ExactSameForAllColumns(DoNothing), None),
    formatter: format_row,
  )
}

/// Start building a `Formatter` column by column.
/// 
/// This function creates an empty formatter with an as-of-yet unspecified type, which when used always returns an empty row.
/// To *actually* create a working `Formatter`, use the [`format.column`](format.html#column) function to specify how to fill each subsequent column.
/// 
pub fn init() -> Formatter(a) {
  Formatter(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    metadata_separator: ":",
    escape_all: False,
    column_data: #(ExactSameForAllColumns(DoNothing), Some([])),
    formatter: fn(_) { [] },
  )
}

pub fn column(
  formatter: Formatter(a),
  column_name: String,
  format_col: fn(a) -> String,
) -> Formatter(a) {
  Formatter(
    ..formatter,
    column_data: #(
      formatter.column_data.0,
      formatter.column_data.1
        |> option.map(list.append(_, [column_name])),
    ),
    formatter: fn(value: a) -> List(String) {
      value
      |> formatter.formatter()
      |> list.append([format_col(value)])
    },
  )
}

pub fn column_whitespace(
  formatter: Formatter(a),
  whitespace_behaviour: ColumnWhitespaceBehaviour,
) -> Formatter(a) {
  let col_behaviour = fn(existing_col_behaviour, pad_with) {
    case formatter.column_data.1 {
      Some(l) ->
        existing_col_behaviour
        |> pad_list_end_with(list.length(l) - 1, pad_with)
        |> list.append([whitespace_behaviour])
      None ->
        existing_col_behaviour
        |> list.append([whitespace_behaviour])
    }
  }

  let make_col_behaviour = fn(existing_col_behaviour) {
    case existing_col_behaviour {
      [] -> col_behaviour(existing_col_behaviour, DoNothing)
      [head, ..] -> col_behaviour(existing_col_behaviour, head)
    }
  }

  let column_whitespace_behaviour = case formatter.column_data.0 {
    ExactSameForAllColumns(global) ->
      // If there is a globally specified column behaviour, use it to pad the list
      SpecifiedForStartingColumns(make_col_behaviour([global]))
    SpecifiedForStartingColumns(cols) ->
      SpecifiedForStartingColumns(make_col_behaviour(cols))
  }
  Formatter(..formatter, column_data: #(
    column_whitespace_behaviour,
    formatter.column_data.1,
  ))
}

/// Function to set a specific row separator, instead of the default newline (`\n`)
/// 
/// If the row separator chosen is longer than a single character, it might cause problems
/// with performance later during parsing.
/// 
pub fn set_row_sep(
  formatter: Formatter(a),
  new_row_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, row_separator: new_row_separator)
}

/// Function to set a specific column separator, instead of the default comma (`,`)
/// 
/// If the column separator chosen is longer than a single character, it might cause problems
/// with performance later during parsing.
/// 
pub fn set_col_sep(
  formatter: Formatter(a),
  new_column_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, column_separator: new_column_separator)
}

/// Function to manually set column headers in a particular order.
/// 
/// By default, no headers will be written to output String, and the first row will
/// directly be the formatted data.
/// 
pub fn set_headers(
  formatter: Formatter(a),
  new_headers: List(String),
) -> Formatter(a) {
  Formatter(..formatter, column_data: #(
    formatter.column_data.0,
    Some(new_headers),
  ))
}

/// Function to manually set row whitespace behaviour.
/// 
/// For more easily understandable control over this, consider using a column-based
/// `Formatter` builder through [`format.init`](format.html#init) and
/// [`format.column`](format.html#column).
/// 
pub fn set_row_whitespace(
  formatter: Formatter(a),
  whitespace_behaviour: RowWhitespaceBehaviour,
) -> Formatter(a) {
  Formatter(..formatter, column_data: #(
    whitespace_behaviour,
    formatter.column_data.1,
  ))
}

/// Function to set custom escaper (character that wraps the value if its'
/// string contains row or column separators, or the escaper itself)
/// 
pub fn set_escaper(
  formatter: Formatter(a),
  new_escaper: String,
) -> Formatter(a) {
  Formatter(..formatter, escaper: new_escaper)
}

/// Function to set custom metadata separator - ie, the character that separates the metadata
/// `key` from its `value`.
/// 
/// By default, it's `:`
/// 
pub fn set_meta_sep(
  formatter: Formatter(a),
  new_metadata_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, metadata_separator: new_metadata_separator)
}

/// Function to specify whether to wrap each value in an escaper, regardles of necessity.
/// 
/// By default false.
/// 
pub fn set_escape_all(parser: Formatter(a), escape_all: Bool) -> Formatter(a) {
  Formatter(..parser, escape_all: escape_all)
}

// => Execution Functions

/// Execution function that takes in a `Formatter(a)` as well as a `List(#(String, String))`,
/// and uses the configured separators and escapers to format the provided metadata and
/// headers into a String, and updating the `Formatter` to avoid duplicating headers when
/// it is passed into the [`format.run`](format.html#run) function.
/// 
/// The `List` being passed in should follow the structure one would use to create a `dict`
/// - that being, the first `String` of the tuple is the key, and the second is the value.
/// 
/// All of the configuration options need to be set when building the `Formatter`, so this
/// function should be very simple to understand.
/// 
/// After calling this function, you can also use the [`format.then`](format.html#then)
/// function to cleanly call the [`run`](format.html#run) function instead of having to
/// deconstruct the output tuple yourself.
/// 
pub fn preprocess(
  formatter: Formatter(a),
  metadata: List(#(String, String)),
) -> #(Formatter(a), String) {
  case metadata {
    [] -> #(formatter, "")
    non_empty -> {
      let #(whitespace, maybe_headers) = formatter.column_data
      let metadata =
        non_empty
        |> list.map(make_metadata_formatter(formatter))
        |> string.join("")
        |> wrap(in: "---" <> formatter.row_separator)
      case maybe_headers {
        Some(headers) -> {
          let row =
            headers
            |> make_whitespace_processor(formatter)
            |> list.map(make_ensafeify(formatter, Data))
            |> string.join(formatter.column_separator)
          #(
            Formatter(..formatter, column_data: #(whitespace, None)),
            metadata <> row <> formatter.row_separator,
          )
        }
        None -> #(formatter, metadata)
      }
    }
  }
}

/// Helper function to use after calling the [`format.preprocess`](format.html#preprocess)
/// function to format metadata using a configured `Formatter`. Use it just as you would
/// the [`format.run`](format.html#run) function, just only after calling the `preprocess`.
/// 
pub fn then(in: #(Formatter(a), String), format: List(a)) -> String {
  let #(formatter, string) = in

  string <> run(formatter, format)
}

/// Execution function that takes in a `Formatter(a)` as well as a `List(a)`, and encodes
/// it into a String.
/// 
/// All of the configuration options need to be set when building the `Formatter`, so
/// this function should be very simple to understand.
/// 
/// If you run this function without first running [`format.preprocess`](format.html#preprocess),
/// it will still prepend the headers row to the output CSV file, if you specified them. However,
/// if you do first call `preprocess`, then `preprocess` will be the function which adds the
/// header row, and the returned `Formatter` will be modified to not add any headers. So,
/// unless you discard the modified `Formatter` returned from the `preprocess` function and
/// reuse the original one while still using the metadata `String` returned by `preprocess`,
/// the headers will not be duplicated.
/// 
pub fn run(formatter: Formatter(a), elements: List(a)) -> String {
  let Formatter(
    column_separator,
    row_separator,
    _escaper,
    _metadata_separator,
    _escape_all,
    #(_whitespace, maybe_headers),
    to_string,
  ) = formatter

  case maybe_headers {
    Some(headers) -> [headers, ..elements |> list.map(to_string)]
    None -> elements |> list.map(to_string)
  }
  |> list.map(fn(values: List(String)) -> String {
    values
    |> make_whitespace_processor(formatter)
    |> list.map(make_ensafeify(formatter, Data))
    |> string.join(column_separator)
  })
  |> string.join(row_separator)
}

/// > **This function is deprecated, and should be replaced with the
///   [`format.run`](format.html#run) function.**
/// 
/// Execution function that takes in a `Formatter(a)` as well as a `List(a)`,
/// and encodes it into a String.
/// 
@deprecated("
To simplify the API and comply with the Gleam convention, I have decided to rename the format
function to `run`. This function is still available to call, but should be replaced if possible.
In new code, use the `run` function.
")
pub fn format(formatter: Formatter(a), elements: List(a)) -> String {
  run(formatter, elements)
}

// ==== Private Functions ====

fn process_cell_whitespace(
  cell: String,
  behaviour: ColumnWhitespaceBehaviour,
) -> String {
  case behaviour {
    DoNothing -> cell
    TrimAll -> string.trim(cell)
    TrimStart -> string.trim_start(cell)
    LeftAlignPad(length) ->
      string.trim(cell) |> string.pad_end(to: length, with: " ")
    RightAlignPad(length) ->
      string.trim(cell) |> string.pad_start(to: length, with: " ")
  }
}

fn make_whitespace_processor(
  formatter: Formatter(a),
) -> fn(List(String)) -> List(String) {
  let whitespace = formatter.column_data.0
  fn(cells: List(String)) -> List(String) {
    case whitespace {
      ExactSameForAllColumns(col_behaviour) ->
        cells
        |> list.map(process_cell_whitespace(_, col_behaviour))
      SpecifiedForStartingColumns(behaviours) ->
        cells
        |> util.map2_default(behaviours, DoNothing, process_cell_whitespace)
    }
  }
}

/// Internal helper function for creating a function that checks if a specific element needs
/// to be escaped (wrapped in escaper, which by default is `"`) before being written to file.
/// 
/// It's a curried function because I like functional programming, and because it *should*
/// give some performance improvements if I create such a function before any looping instead
/// of constructing one for each iteration.
/// 
fn needs_escaping(prohibited: List(String)) -> fn(String) -> Bool {
  fn(el: String) -> Bool {
    prohibited
    |> list.any(fn(s: String) -> Bool { string.contains(el, s) })
  }
}

/// Internal helper function for creating a function that wraps a String in the specified
/// 'escaper' String.
/// 
/// It's a curried function because I like functional programming, and because it *should*
/// give some performance improvements if I create such a function before any looping instead
/// of constructing one for each iteration.
/// 
fn wrap(in in: String) -> fn(String) -> String {
  fn(el: String) -> String { in <> el <> in }
}

fn escapeify(formatter: Formatter(a)) -> fn(String) -> String {
  let escaper = formatter.escaper
  fn(el: String) -> String {
    el
    |> util.multi_replace([#(escaper, escaper <> escaper)])
    |> wrap(in: escaper)
  }
}

fn make_to_escape(
  formatter: Formatter(a),
  field: EscapeWhich,
) -> fn(String) -> Bool {
  case field {
    Metadata -> [
      formatter.row_separator,
      formatter.metadata_separator,
      formatter.escaper,
      "\n",
      "\r",
    ]
    Data -> [
      formatter.column_separator,
      formatter.row_separator,
      formatter.escaper,
      "\n",
      "\r",
    ]
  }
  |> needs_escaping()
}

fn make_ensafeify(
  formatter: Formatter(a),
  field: EscapeWhich,
) -> fn(String) -> String {
  let ensafeify = escapeify(formatter)
  fn(val: String) -> String {
    case formatter.escape_all || make_to_escape(formatter, field)(val) {
      True -> ensafeify(val)
      False -> val
    }
  }
}

fn make_metadata_formatter(
  formatter: Formatter(a),
) -> fn(#(String, String)) -> String {
  let ensafeify = make_ensafeify(formatter, Metadata)
  fn(metadata: #(String, String)) -> String {
    ensafeify(metadata.0)
    <> ":"
    <> ensafeify(metadata.1)
    <> formatter.row_separator
  }
}
