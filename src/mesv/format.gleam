import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// The type describing how to convert a specified data type `a` into String form.
/// 
/// To create it, use the `build` function and the provided transformation functions
/// (`set_row_sep`, `set_col_sep`, `set_headers`, `set_escaper`) to configure the specific behaviour.
/// 
/// Once you have the required `Formatter(a)`, use the `format` function to convert a `List(a)` into a String.
/// 
pub opaque type Formatter(a) {
  Formatter(
    column_separator: String,
    row_separator: String,
    escaper: String,
    escape_all: Bool,
    headers: Option(List(String)),
    formatter: fn(a) -> List(String),
  )
}

/// Function for directly building a `Formatter` that outputs the specified elements in an exact order
/// 
pub fn build(f: fn(a) -> List(String)) -> Formatter(a) {
  Formatter(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    escape_all: False,
    headers: None,
    formatter: f,
  )
}

/// Function to set a specific row separator, instead of the default newline (`\n`)
/// 
/// If the row separator chosen is longer than a single character, it might cause problems with performance later
/// during parsing.
/// 
pub fn set_row_sep(
  formatter: Formatter(a),
  new_row_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, row_separator: new_row_separator)
}

/// Function to set a specific column separator, instead of the default comma (`,`)
/// 
/// If the column separator chosen is longer than a single character, it might cause problems with performance later
/// during parsing.
/// 
pub fn set_col_sep(
  formatter: Formatter(a),
  new_column_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, column_separator: new_column_separator)
}

/// Function to manually set column headers in a particular order.
/// 
/// By default, the headers will not be written to output String.
/// 
pub fn set_headers(
  formatter: Formatter(a),
  new_headers: List(String),
) -> Formatter(a) {
  Formatter(..formatter, headers: Some(new_headers))
}

/// Function to set custom escaper
/// (character that wraps the value if its' string contains row or column separators, or the escaper itself)
/// 
pub fn set_escaper(
  formatter: Formatter(a),
  new_escaper: String,
) -> Formatter(a) {
  Formatter(..formatter, escaper: new_escaper)
}

/// Function to specify whether to wrap each value in an escaper, regardles of necessity.
/// 
/// By default false.
/// 
pub fn set_escape_all(parser: Formatter(a), escape_all: Bool) -> Formatter(a) {
  Formatter(..parser, escape_all: escape_all)
}

/// Internal helper function for creating a function that checks if a specific element needs to be escaped
/// (wrapped in escaper, which by default is `"`) before being written to file.
/// 
/// It's a curried function because I like functional programming, and because it *should* give some performance improvements
/// if I create such a function before any looping instead of constructing one for each iteration.
/// 
fn needs_escaping(prohibited: List(String)) -> fn(String) -> Bool {
  fn(el: String) -> Bool {
    prohibited |> list.any(fn(s: String) -> Bool { string.contains(el, s) })
  }
}

/// Internal helper function for creating a function for 'escaping' an element
/// (for each `rule`, replacing the first element in the tuple with the second).
/// 
/// It's a curried function because I like functional programming, and because it *should* give some performance improvements
/// if I create such a function before any looping instead of constructing one for each iteration.
/// 
fn escape(rules: List(#(String, String))) -> fn(String) -> String {
  fn(el: String) -> String {
    rules
    |> list.map(fn(rule: #(String, String)) -> fn(String) -> String {
      string.replace(each: rule.0, with: rule.1, in: _)
    })
    |> list.fold(el, fn(acc: String, rule: fn(String) -> String) -> String {
      rule(acc)
    })
  }
}

/// Internal helper function for creating a function that wraps a String in the specified 'escaper' String.
/// 
/// It's a curried function because I like functional programming, and because it *should* give some performance improvements
/// if I create such a function before any looping instead of constructing one for each iteration.
/// 
fn wrap(in in: String) -> fn(String) -> String {
  fn(el: String) -> String { in <> el <> in }
}

/// Execution function that takes in a `Formatter(a)` as well as a `List(a)`, and encodes it into a String.
/// 
/// All of the configuration options need to be set when building the `Formatter`,
/// so this function is very simple to understand.
/// 
pub fn format(formatter: Formatter(a), elements: List(a)) -> String {
  let Formatter(
    column_separator,
    row_separator,
    escaper,
    escape_all,
    maybe_headers,
    to_string,
  ) = formatter

  // For each separate element (column value in specific row) replace the first String with the second
  let rules = [#(escaper, escaper <> escaper)]
  let escapeify = fn(el: String) -> String {
    el
    |> string.trim()
    |> escape(rules)
    |> wrap(in: escaper)
  }
  let to_escape =
    needs_escaping([
      column_separator,
      row_separator,
      escaper,
      "\n",
      "\r",
    ])

  let ensafeify = fn(val: String) -> String {
    case escape_all || to_escape(val) {
      True -> escapeify(val)
      False -> val
    }
  }

  case maybe_headers {
    Some(headers) -> [headers, ..elements |> list.map(to_string)]
    None -> elements |> list.map(to_string)
  }
  |> list.map(fn(values: List(String)) -> String {
    values
    |> list.map(string.trim)
    |> list.map(ensafeify)
    |> string.join(column_separator)
  })
  |> string.join(row_separator)
}
