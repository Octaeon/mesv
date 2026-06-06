//// A test module focuisng on ensuring that round trips (that is, data -> formatting -> parsing) are equivalent to identity functions,
//// as long as all of the fields in a data type are formatted.
//// 
//// Formally, ensuring that if in code, `format(a) -> List(String)` and `parse(List(String)) -> a` satisfy the condition
//// `a == parse(format(a))`, then using the `mesv.format` and `mesv.parse` modules to convert to csv and back will satisfy the condition
//// `List(a) == mesv.parse(mesv.format(List(a)))`, no matter the specified separators and escapers.
//// 
//// This module is for testing this property for formatting and parsing metadata along with normal CSV data.
//// 

import gleam/list
import gleam/result
import mesv/format.{type Formatter}
import mesv/parse.{
  type DataRowError, type Parser, type PreprocessingError, InOrderExact, Text,
}
import mesv_test.{type RowData}

fn build_test_unit_parser_and_formatter(
  col_sep: String,
  row_sep: String,
  meta_sep: String,
  escaper: String,
) -> #(Formatter(RowData), Parser(RowData, Nil)) {
  #(
    mesv_test.row_data_formatter(col_sep, row_sep, escaper)
      |> format.set_meta_sep(meta_sep),
    mesv_test.row_data_parser(col_sep, row_sep, escaper)
      |> parse.set_meta_sep(meta_sep),
  )
}

fn build_test_unit(
  col_sep: String,
  row_sep: String,
  meta_sep: String,
  escaper: String,
) -> fn(List(#(String, String)), List(RowData)) ->
  Result(
    #(List(#(String, String)), List(Result(RowData, DataRowError(Nil)))),
    PreprocessingError,
  ) {
  let #(formatter, parser) =
    build_test_unit_parser_and_formatter(col_sep, row_sep, meta_sep, escaper)
  let headers = ["Name", "Age", "Comment"]
  fn(metadata: List(#(String, String)), rows: List(RowData)) {
    formatter
    |> format.set_headers(headers)
    |> format.preprocess(metadata)
    |> format.then(rows)
    |> fn(str: String) {
      parser
      |> parse.set_expected_headers(InOrderExact(headers))
      |> parse.preprocess(Text(str))
      // |> result.map_error(fn(_) { RanOutOfValues })
      |> result.map(fn(preprocess_out) {
        let #(parsed_metadata, parser, csv_source) = preprocess_out
        #(parsed_metadata, parse.run(parser, csv_source))
      })
    }
  }
}

fn wrap(
  meta: List(#(String, String)),
  val: List(a),
) -> Result(
  #(List(#(String, String)), List(Result(a, DataRowError(Nil)))),
  PreprocessingError,
) {
  Ok(#(meta, val |> list.map(Ok)))
}

const empty_metadata = []

pub fn default_normal_empty_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  assert parsed(empty_metadata, mesv_test.normal_data())
    == wrap(empty_metadata, mesv_test.normal_data())
    as "Round trip default parameters | Empty metadata, normal"
}

pub fn default_column_separator_empty_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(empty_metadata, mesv_test.column_separator_data(col_sep))
    == wrap(empty_metadata, mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Empty metadata, column separator"
}

pub fn default_row_separator_empty_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(empty_metadata, mesv_test.row_separator_data(row_sep))
    == wrap(empty_metadata, mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Empty metadata, row separator"
}

pub fn default_escaper_empty_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(empty_metadata, mesv_test.escaper_data(esc))
    == wrap(empty_metadata, mesv_test.escaper_data(esc))
    as "Round trip default parameters | Empty metadata, escaper"
}

const single_row_metadata: List(#(String, String)) = [#("test", "metadata")]

pub fn default_normal_single_row_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  assert parsed(single_row_metadata, mesv_test.normal_data())
    == wrap(single_row_metadata, mesv_test.normal_data())
    as "Round trip default parameters | Metadata single line, normal"
}

pub fn default_column_separator_single_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(single_row_metadata, mesv_test.column_separator_data(col_sep))
    == wrap(single_row_metadata, mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Metadata single line, column separator"
}

pub fn default_row_separator_single_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(single_row_metadata, mesv_test.row_separator_data(row_sep))
    == wrap(single_row_metadata, mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Metadata single line, row separator"
}

pub fn default_escaper_single_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(single_row_metadata, mesv_test.escaper_data(esc))
    == wrap(single_row_metadata, mesv_test.escaper_data(esc))
    as "Round trip default parameters | Metadata single line, escaper"
}

const multi_row_metadata: List(#(String, String)) = [
  #("this", "time"),
  #("there", "will"),
  #("be", "multiple"),
  #("rows", ""),
]

pub fn default_normal_multi_row_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  assert parsed(multi_row_metadata, mesv_test.normal_data())
    == wrap(multi_row_metadata, mesv_test.normal_data())
    as "Round trip default parameters | Metadata multiple lines, normal"
}

pub fn default_column_separator_multi_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(multi_row_metadata, mesv_test.column_separator_data(col_sep))
    == wrap(multi_row_metadata, mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Metadata multiple lines, column separator"
}

pub fn default_row_separator_multi_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(multi_row_metadata, mesv_test.row_separator_data(row_sep))
    == wrap(multi_row_metadata, mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Metadata multiple lines, row separator"
}

pub fn default_escaper_multi_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(multi_row_metadata, mesv_test.escaper_data(esc))
    == wrap(multi_row_metadata, mesv_test.escaper_data(esc))
    as "Round trip default parameters | Metadata multiple lines, escaper"
}

pub fn default_normal_empty_key_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  let metadata = [#("", "oh no, my key is empty, whatever will i do")]

  assert parsed(metadata, mesv_test.normal_data())
    == wrap(metadata, mesv_test.normal_data())
    as "Round trip default parameters | Metadata empty key"
}

pub fn default_normal_escaped_key_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  let metadata = [#(":", "you can't do that")]

  assert parsed(metadata, mesv_test.normal_data())
    == wrap(metadata, mesv_test.normal_data())
    as "Round trip default parameters | Metadata escaped key"
}

pub fn default_normal_escaped_value_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  let metadata = [#("why not? you try", "oh sh:t, i can")]

  assert parsed(metadata, mesv_test.normal_data())
    == wrap(metadata, mesv_test.normal_data())
    as "Round trip default parameters | Metadata escaped value"
}
