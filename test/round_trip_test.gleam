//// A test module focuisng on ensuring that round trips (that is, data -> formatting -> parsing) are equivalent to identity functions,
//// as long as all of the fields in a data type are formatted.
//// 
//// Formally, ensuring that if in code, `format(a) -> List(String)` and `parse(List(String)) -> a` satisfy the condition
//// `a == parse(format(a))`, then using the `mesv.format` and `mesv.parse` modules to convert to csv and back will satisfy the condition
//// `List(a) == mesv.parse(mesv.format(List(a)))`, no matter the specified separators and escapers.

import gleam/int
import mesv
import mesv/format.{type Formatter}
import mesv/parse.{type Parser}
import mesv_test.{type RowData, RowData}

fn build_test_unit_parser_and_formatter(
  col_sep: String,
  row_sep: String,
  escaper: String,
) -> #(Formatter(RowData), Parser(RowData)) {
  let formatter =
    format.build(fn(row: RowData) -> List(String) {
      let RowData(name, age, comment) = row
      [name, int.to_string(age), comment]
    })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(escaper)
  let parser =
    parse.build({
      use name <- mesv.parsed
      use age <- mesv.parsed
      use comment <- mesv.parsed
      RowData(name, age, comment)
    })
    |> parse.column(Ok)
    |> parse.column(int.parse)
    |> parse.column(Ok)
    |> parse.set_col_sep(col_sep)
    |> parse.set_row_sep(row_sep)
    |> parse.set_escaper(escaper)
  #(formatter, parser)
}

fn build_test_unit(
  col_sep: String,
  row_sep: String,
  escaper: String,
) -> fn(List(RowData)) ->
  Result(#(List(RowData), List(parse.ParsingError)), parse.ParsingError) {
  fn(rows: List(RowData)) -> Result(
    #(List(RowData), List(parse.ParsingError)),
    parse.ParsingError,
  ) {
    let #(formatter, parser) =
      build_test_unit_parser_and_formatter(col_sep, row_sep, escaper)

    rows
    |> format.format(formatter, _)
    |> parse.parse(parser, _)
  }
}

fn wrap(val: a) -> Result(#(a, _), _) {
  Ok(#(val, []))
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
