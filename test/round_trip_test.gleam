//// A test module focuisng on ensuring that round trips (that is, data -> formatting -> parsing) are equivalent to identity functions,
//// as long as all of the fields in a data type are formatted.
//// 
//// Formally, ensuring that if in code, `format(a) -> List(String)` and `parse(List(String)) -> a` satisfy the condition
//// `a == parse(format(a))`, then using the `mesv.format` and `mesv.parse` modules to convert to csv and back will satisfy the condition
//// `List(a) == mesv.parse(mesv.format(List(a)))`, no matter the specified separators and escapers.

import gleam/list
import gleam/result
import mesv/format.{type Formatter}
import mesv/parse.{
  type DataRowError, type Parser, type PreprocessingError, InOrderExact,
  RowStream,
}
import mesv/stream
import mesv_test.{type RowData}

fn build_test_unit_parser_and_formatter(
  col_sep: String,
  row_sep: String,
  escaper: String,
) -> #(Formatter(RowData), Parser(RowData, Nil)) {
  #(
    mesv_test.row_data_formatter(col_sep, row_sep, escaper),
    mesv_test.row_data_parser(col_sep, row_sep, escaper),
  )
}

fn build_test_unit(
  col_sep: String,
  row_sep: String,
  escaper: String,
) -> fn(List(RowData)) ->
  Result(List(Result(RowData, DataRowError(Nil))), PreprocessingError) {
  let #(formatter, parser) =
    build_test_unit_parser_and_formatter(col_sep, row_sep, escaper)

  let headers = ["Name", "Age", "Comment"]

  fn(rows: List(RowData)) {
    formatter
    |> format.set_headers(headers)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(rows))
    |> fn(in) {
      let #(_, stream) = in
      parser
      |> parse.set_expected_headers(InOrderExact(headers))
      |> parse.preprocess(RowStream(stream))
      |> parse.then_run()
      // |> parse.just_data()
      |> result.map(fn(preprocessing_output) {
        stream.to_list(preprocessing_output.1)
      })
    }
  }
}

fn wrap(val: List(a)) -> Result(List(Result(a, e)), PreprocessingError) {
  Ok(val |> list.map(Ok))
}

pub fn default_normal_test() -> Nil {
  let parsed = build_test_unit(",", "\n", "\"")

  assert parsed(mesv_test.normal_data()) == wrap(mesv_test.normal_data())
    as "Round trip default parameters | Normal"
}

pub fn default_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip default parameters | Column separator"
}

pub fn default_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip default parameters | Row separator"
}

pub fn default_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip default parameters | Escaper"
}

// Custom column separator tests
pub fn custom_col_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.normal_data()) == wrap(mesv_test.normal_data())
    as "Round trip custom column separator | Normal"
}

pub fn custom_col_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip custom column separator | Column separator"
}

pub fn custom_col_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip custom column separator | Row separator"
}

pub fn custom_col_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip custom column separator | Escaper"
}

// Custom row separator tests
pub fn custom_row_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.normal_data()) == wrap(mesv_test.normal_data())
    as "Round trip custom row separator | Normal"
}

pub fn custom_row_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip custom row separator | Column separator"
}

pub fn custom_row_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip custom row separator | Row separator"
}

pub fn custom_row_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip custom row separator | Escaper"
}

// Custom escaper tests
pub fn custom_esc_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.normal_data()) == wrap(mesv_test.normal_data())
    as "Round trip custom escaper | Normal"
}

pub fn custom_esc_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip custom escaper | Column separator"
}

pub fn custom_esc_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip custom escaper | Row separator"
}

pub fn custom_esc_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip custom escaper | Escaper"
}

// Combined tests
pub fn combined_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.normal_data()) == wrap(mesv_test.normal_data())
    as "Round trip combined | Normal"
}

pub fn combined_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.column_separator_data(col_sep))
    == wrap(mesv_test.column_separator_data(col_sep))
    as "Round trip combined | Column separator"
}

pub fn combined_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.row_separator_data(row_sep))
    == wrap(mesv_test.row_separator_data(row_sep))
    as "Round trip combined | Row separator"
}

pub fn combined_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed = build_test_unit(col_sep, row_sep, esc)

  assert parsed(mesv_test.escaper_data(esc))
    == wrap(mesv_test.escaper_data(esc))
    as "Round trip combined | Escaper"
}
