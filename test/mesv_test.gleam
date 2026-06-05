import gleam/int
import gleam/list
import gleeunit
import mesv
import mesv/parse.{type Parser}

pub type RowData {
  RowData(name: String, age: Int, comment: String)
}

pub fn normal_data() -> List(RowData) {
  [
    RowData("Alex", 23, "This is a pretty cool library"),
    RowData("Bartholemew", 24, "Yeah I agree"),
  ]
}

pub fn column_separator_data(column_separator: String) -> List(RowData) {
  [
    RowData("Alex", 23, "This is a pretty good library, don't you think?"),
    RowData(
      "Bartholemew",
      24,
      "Yeah, it's pretty good, but are you sure it can handle escaping separators? Try "
        <> column_separator
        <> " this. heh",
    ),
  ]
}

pub fn row_separator_data(row_separator: String) -> List(RowData) {
  [
    RowData("Alex", 23, "It should be able to, right?"),
    RowData(
      "Bartholemew",
      24,
      "Maybe column separators,"
        <> row_separator
        <> "but what about row separators?",
    ),
  ]
}

pub fn escaper_data(escaper: String) -> List(RowData) {
  [
    RowData("Bartholemew", 24, "Huh, it worked. Now only escapers remain."),
    RowData("Alex", 23, "What are escapers?"),
    RowData(
      "Bartholemew",
      24,
      "They're what wrap a value if it contains reserved elements. Right now, it's "
        <> escaper,
    ),
  ]
}

pub fn expected_normal_data() -> List(Result(RowData, b)) {
  normal_data() |> list.map(Ok)
}

pub fn expected_column_separator_data(
  col_sep: String,
) -> List(Result(RowData, b)) {
  column_separator_data(col_sep) |> list.map(Ok)
}

pub fn expected_row_separator_data(
  row_sep: String,
) -> List(Result(RowData, b)) {
  row_separator_data(row_sep) |> list.map(Ok)
}

pub fn expected_escaper_data(esc: String) -> List(Result(RowData, b)) {
  escaper_data(esc) |> list.map(Ok)
}

pub fn build_test_unit_parser(
  col_sep: String,
  row_sep: String,
  escaper: String,
) -> Parser(RowData) {
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
}

/// Main function that acts as the entrypoint for the testing library `gleeunit`.
/// 
/// By calling `gleeunit.main()`, it will scan all of the files in the root `test` folder,
/// and call all functions that end in `_test`.
/// 
/// These test functions should return `Nil`, and any function that panics is considered failed.
pub fn main() -> Nil {
  gleeunit.main()
}
