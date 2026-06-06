//// A test module focuisng on ensuring that round trips (that is, data -> formatting -> parsing) are equivalent to identity functions,
//// as long as all of the fields in a data type are formatted.
//// 
//// Formally, ensuring that if in code, `format(a) -> List(String)` and `parse(List(String)) -> a` satisfy the condition
//// `a == parse(format(a))`, then using the `mesv.format` and `mesv.parse` modules to convert to csv and back will satisfy the condition
//// `List(a) == mesv.parse(mesv.format(List(a)))`, no matter the specified separators and escapers.

import gleam/list
import gleam/result
import mesv/format.{type Formatter}
import mesv/parse.{type Parser, type ParsingError, RanOutOfValues, Text}
import mesv_test.{type RowData}

fn build_test_unit_parser_and_formatter(
  col_sep: String,
  row_sep: String,
  meta_sep: String,
  escaper: String,
) -> #(Formatter(RowData), Parser(RowData)) {
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
  Result(List(Result(RowData, ParsingError)), ParsingError) {
  fn(metadata: List(#(String, String)), rows: List(RowData)) -> Result(
    List(Result(RowData, ParsingError)),
    ParsingError,
  ) {
    let #(formatter, parser) =
      build_test_unit_parser_and_formatter(col_sep, row_sep, meta_sep, escaper)

    formatter
    |> format.preprocess(metadata)
    |> format.then(rows)
    |> fn(str: String) {
      parse.preprocess(parser, Text(str))
      |> result.map_error(fn(_) { RanOutOfValues })
      |> result.try(fn(preprocess_out) {
        let #(parsed_metadata, parser, csv_source) = preprocess_out
        case metadata == parsed_metadata {
          True -> parse.run(parser, csv_source)
          False -> Error(RanOutOfValues)
        }
      })
    }
  }
}

fn wrap(val: List(a)) -> Result(List(Result(a, ParsingError)), ParsingError) {
  Ok(val |> list.map(Ok))
}

pub fn default_normal_empty_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  assert parsed([], mesv_test.normal_data()) == wrap(mesv_test.normal_data())
    as "Round trip default parameters | Normal"
}

pub fn default_column_separator_empty_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed([], mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Column separator"
}

pub fn default_row_separator_empty_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed([], mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Row separator"
}

pub fn default_escaper_empty_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed([], mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip default parameters | Escaper"
}

const single_row_metadata: List(#(String, String)) = [#("test", "metadata")]

pub fn default_normal_single_row_test() -> Nil {
  let parsed = build_test_unit(",", "\n", ":", "\"")

  assert parsed(single_row_metadata, mesv_test.normal_data())
    == wrap(mesv_test.normal_data())
    as "Round trip default parameters | Normal"
}

pub fn default_column_separator_single_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(single_row_metadata, mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Column separator"
}

pub fn default_row_separator_single_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(single_row_metadata, mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Row separator"
}

pub fn default_escaper_single_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(single_row_metadata, mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip default parameters | Escaper"
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
    == wrap(mesv_test.normal_data())
    as "Round trip default parameters | Normal"
}

pub fn default_column_separator_multi_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(multi_row_metadata, mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Column separator"
}

pub fn default_row_separator_multi_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(multi_row_metadata, mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Row separator"
}

pub fn default_escaper_multi_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let meta_sep = ":"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, meta_sep, esc)

  assert parsed(multi_row_metadata, mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip default parameters | Escaper"
}
