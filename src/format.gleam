import gleam/list
import gleam/string

pub opaque type Formatter(a) {
  Formatter(
    column_separator: String,
    row_separator: String,
    headers: List(String),
    formatter: fn(a) -> List(String),
  )
}

/// A function for creating a `Formatter`
pub fn build(f: fn(a) -> List(String)) -> Formatter(a) {
  Formatter(
    column_separator: ",",
    row_separator: "\n",
    headers: [],
    formatter: f,
  )
}

pub fn set_row_sep(
  formatter: Formatter(a),
  new_row_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, row_separator: new_row_separator)
}

pub fn set_col_sep(
  formatter: Formatter(a),
  new_column_separator: String,
) -> Formatter(a) {
  Formatter(..formatter, column_separator: new_column_separator)
}

pub fn set_headers(
  formatter: Formatter(a),
  new_headers: List(String),
) -> Formatter(a) {
  Formatter(..formatter, headers: new_headers)
}

fn needs_escaping(el: String, prohibited: List(String)) -> Bool {
  prohibited |> list.any(fn(s: String) -> Bool { string.contains(el, s) })
}

fn escape(el: String, rules: List(#(String, String))) -> String {
  rules
  |> list.map(fn(rule: #(String, String)) -> fn(String) -> String {
    string.replace(each: rule.0, with: rule.1, in: _)
  })
  |> list.fold(el, fn(acc: String, rule: fn(String) -> String) -> String {
    rule(acc)
  })
}

pub fn format(formatter: Formatter(a), elements: List(a)) -> String {
  let Formatter(column_separator, row_separator, headers, to_string) = formatter

  // For each separate element (column value in specific row) replace the first String with the second
  let rules = [#("\"", "\"\"")]

  [headers, ..elements |> list.map(to_string)]
  |> list.map(fn(values: List(String)) -> String {
    values
    |> list.map(string.trim)
    |> list.map(fn(val: String) -> String {
      case
        needs_escaping(val, [
          column_separator,
          row_separator,
          ",",
          "\"",
          "\n",
          "\r",
        ])
      {
        True -> "\"" <> escape(val, rules) <> "\""
        False -> val
      }
    })
    |> string.join(column_separator)
  })
  |> string.join(row_separator)
}
