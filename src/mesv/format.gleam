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
    headers: Option(List(String)),
    formatter: fn(a) -> List(String),
  )
}

type EscapeWhich {
  Metadata
  Data
}

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
pub fn build(f: fn(a) -> List(String)) -> Formatter(a) {
  Formatter(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    metadata_separator: ":",
    escape_all: False,
    headers: None,
    formatter: f,
  )
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
  Formatter(..formatter, headers: Some(new_headers))
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
    maybe_headers,
    to_string,
  ) = formatter

  case maybe_headers {
    Some(headers) -> [headers, ..elements |> list.map(to_string)]
    None -> elements |> list.map(to_string)
  }
  |> list.map(fn(values: List(String)) -> String {
    values
    |> list.map(make_ensafeify(formatter, Data))
    |> string.join(column_separator)
  })
  |> string.join(row_separator)
}

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
      let metadata =
        non_empty
        |> list.map(make_metadata_formatter(formatter))
        |> string.join("")
        |> wrap(in: "---" <> formatter.row_separator)
      case formatter.headers {
        Some(headers) -> {
          let row =
            headers
            |> list.map(make_ensafeify(formatter, Data))
            |> string.join(formatter.column_separator)
          #(
            Formatter(..formatter, headers: None),
            metadata <> row <> formatter.row_separator,
          )
        }
        None -> #(formatter, metadata)
      }
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

/// Helper function to use after calling the [`format.preprocess`](format.html#preprocess)
/// function to format metadata using a configured `Formatter`. Use it just as you would
/// the [`format.run`](format.html#run) function, just only after calling the `preprocess`.
/// 
pub fn then(in: #(Formatter(a), String), format: List(a)) -> String {
  let #(formatter, string) = in

  string <> run(formatter, format)
}
