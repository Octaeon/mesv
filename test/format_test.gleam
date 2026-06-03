import format.{type Formatter}
import gleam/int

type RowData {
  RowData(name: String, age: Int, comment: String)
}

const normal_data: List(RowData) = [
  RowData("Alex", 23, "This is a pretty cool library"),
  RowData("Bartholemew", 24, "Yeah I agree"),
]

fn column_separator_data(column_separator: String) -> List(RowData) {
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

fn row_separator_data(row_separator: String) -> List(RowData) {
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

fn escaper_data(escaper: String) -> List(RowData) {
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

fn format_row_data(row: RowData) -> List(String) {
  let RowData(name, age, comment) = row
  [name, int.to_string(age), comment]
}

fn build_test_unit_formatter(
  to_str: fn(RowData) -> List(String),
  col_sep: String,
  row_sep: String,
  escaper: String,
) -> Formatter(RowData) {
  to_str
  |> format.build()
  |> format.set_col_sep(col_sep)
  |> format.set_row_sep(row_sep)
  |> format.set_escaper(escaper)
}

pub fn default_normal_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(normal_data)

  assert formatted
    == "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Default parameters, normal data test"
}

pub fn default_column_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(column_separator_data(col_sep))

  assert formatted
    == "Alex,23,\"This is a pretty good library, don't you think?\"\nBartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\""
    as "Default parameters, column separator data test"
}

pub fn default_row_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(row_separator_data(row_sep))

  assert formatted
    == "Alex,23,\"It should be able to, right?\"\nBartholemew,24,\"Maybe column separators,\nbut what about row separators?\""
    as "Default parameters, row separator data test"
}

pub fn default_escaper_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(escaper_data(esc))

  assert formatted
    == "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"\nAlex,23,What are escapers?\nBartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Default parameters, escaper data test"
}

// Custom column separator tests
pub fn custom_col_normal_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(normal_data)

  assert formatted
    == "Alex|23|This is a pretty cool library\nBartholemew|24|Yeah I agree"
    as "Custom column separator, normal data test"
}

pub fn custom_col_column_separator_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(column_separator_data(col_sep))

  assert formatted
    == "Alex|23|This is a pretty good library, don't you think?\nBartholemew|24|\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try | this. heh\""
    as "Custom column separator, column separator data test"
}

pub fn custom_col_row_separator_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(row_separator_data(row_sep))

  assert formatted
    == "Alex|23|It should be able to, right?\nBartholemew|24|\"Maybe column separators,\nbut what about row separators?\""
    as "Custom column separator, row separator data test"
}

pub fn custom_col_escaper_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(escaper_data(esc))

  assert formatted
    == "Bartholemew|24|Huh, it worked. Now only escapers remain.\nAlex|23|What are escapers?\nBartholemew|24|\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Custom column separator, escaper data test"
}

// Custom row separator tests
pub fn custom_row_normal_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(normal_data)

  assert formatted
    == "Alex,23,This is a pretty cool library|Bartholemew,24,Yeah I agree"
    as "Custom row separator, normal data test"
}

pub fn custom_row_column_separator_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(column_separator_data(col_sep))

  assert formatted
    == "Alex,23,\"This is a pretty good library, don't you think?\"|Bartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\""
    as "Custom row separator, column separator data test"
}

pub fn custom_row_row_separator_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(row_separator_data(row_sep))

  assert formatted
    == "Alex,23,\"It should be able to, right?\"|Bartholemew,24,\"Maybe column separators,|but what about row separators?\""
    as "Custom row separator, row separator data test"
}

pub fn custom_row_escaper_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(escaper_data(esc))

  assert formatted
    == "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"|Alex,23,What are escapers?|Bartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Custom row separator, escaper data test"
}

// Custom escaper tests
pub fn custom_esc_normal_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(normal_data)

  assert formatted
    == "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Custom escaper, normal data test"
}

pub fn custom_esc_column_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(column_separator_data(col_sep))

  assert formatted
    == "Alex,23,'This is a pretty good library, don''t you think?'\nBartholemew,24,'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try , this. heh'"
    as "Custom escaper, column separator data test"
}

pub fn custom_esc_row_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(row_separator_data(row_sep))

  assert formatted
    == "Alex,23,'It should be able to, right?'\nBartholemew,24,'Maybe column separators,\nbut what about row separators?'"
    as "Custom escaper, row separator data test"
}

pub fn custom_esc_escaper_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(escaper_data(esc))

  assert formatted
    == "Bartholemew,24,'Huh, it worked. Now only escapers remain.'\nAlex,23,What are escapers?\nBartholemew,24,'They''re what wrap a value if it contains reserved elements. Right now, it''s '''"
    as "Custom escaper, escaper data test"
}

// Combined tests
pub fn combined_normal_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(normal_data)

  assert formatted
    == "Alex|23|This is a pretty cool library;Bartholemew|24|Yeah I agree"
    as "All custom parameters, normal data test"
}

pub fn combined_column_separator_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(column_separator_data(col_sep))

  assert formatted
    == "Alex|23|'This is a pretty good library, don''t you think?';Bartholemew|24|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'"
    as "All custom parameters, column separator data test"
}

pub fn combined_row_separator_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(row_separator_data(row_sep))

  assert formatted
    == "Alex|23|It should be able to, right?;Bartholemew|24|'Maybe column separators,;but what about row separators?'"
    as "All custom parameters, row separator data test"
}

pub fn combined_escaper_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(escaper_data(esc))

  assert formatted
    == "Bartholemew|24|Huh, it worked. Now only escapers remain.;Alex|23|What are escapers?;Bartholemew|24|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''"
    as "All custom parameters, escaper data test"
}
