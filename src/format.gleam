import gleam/list
import gleam/string

pub opaque type Formatter(a) {
  Formatter(
    column_separator: String,
    row_separator: String,
    escaper: String,
    headers: List(String),
    formatter: fn(a) -> List(String),
  )
}

/// Function for directly building a `Formatter` that outputs the specified elements in an exact order
/// 
/// ### Function Declaration
/// ```gleam
/// build(f: fn(a) -> List(String)) -> Formatter(a)
/// ```
/// 
pub fn build(f: fn(a) -> List(String)) -> Formatter(a) {
  Formatter(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    headers: [],
    formatter: f,
  )
}

/// Function to set a specific row separator, instead of the default newline (`\n`)
/// 
/// ### Function Declaration
/// ```gleam
/// set_row_sep(formatter: Formatter(a), new_row_separator: String) -> Formatter(a)
/// ```
/// 
pub fn set_row_sep(
  formatter: Formatter(a),
  new_row_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, row_separator: new_row_separator)
}

/// Function to set a specific column separator, instead of the default comma (`,`)
///
/// ### Function Declaration
/// ```gleam
/// set_col_sep(formatter: Formatter(a), new_column_separator: String) -> Formatter(a)
/// ```
/// 
pub fn set_col_sep(
  formatter: Formatter(a),
  new_column_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, column_separator: new_column_separator)
}

/// Function to manually set column headers in a particular order
///
/// ### Function Declaration
/// ```gleam
/// set_headers(formatter: Formatter(a), new_headers: List(String)) -> Formatter(a)
/// ```
/// 
pub fn set_headers(
  formatter: Formatter(a),
  new_headers: List(String),
) -> Formatter(a) {
  Formatter(..formatter, headers: new_headers)
}

/// Internal helper function for creating a function that checks if a specific element needs to be escaped
/// (wrapped in quotation marks) before being written to file.
/// 
/// ### Function Declaration
/// ```gleam
/// needs_escaping(prohibited: List(String)) -> fn(String) -> Bool
/// ```
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
/// ### Function Declaration
/// ```gleam
/// needs_escaping(el: String, prohibited: List(String)) -> Bool
/// ```
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
/// ### Function Declaration
/// ```gleam
/// needs_escaping(el: String, prohibited: List(String)) -> Bool
/// ```
/// 
/// It's a curried function because I like functional programming, and because it *should* give some performance improvements
/// if I create such a function before any looping instead of constructing one for each iteration.
/// 
fn wrap(in in: String) -> fn(String) -> String {
  fn(el: String) -> String { in <> el <> in }
}

pub fn format(formatter: Formatter(a), elements: List(a)) -> String {
  let Formatter(column_separator, row_separator, escaper, headers, to_string) =
    formatter

  // For each separate element (column value in specific row) replace the first String with the second
  let rules = [#(escaper, escaper <> escaper), #("\"", "\"\"")]
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
      ",",
      "\"",
      "\n",
      "\r",
    ])

  [headers, ..elements |> list.map(to_string)]
  |> list.map(fn(values: List(String)) -> String {
    values
    |> list.map(string.trim)
    |> list.map(fn(val: String) -> String {
      case to_escape(val) {
        True -> escapeify(val)
        False -> val
      }
    })
    |> string.join(column_separator)
  })
  |> string.join(row_separator)
}
