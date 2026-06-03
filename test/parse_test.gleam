import gleam/int
import gleam/result
import mesv
import parse.{type Parser}

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

fn build_test_unit_parser(
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
  |> parse.column(fn(a) {
    int.parse(a)
    |> result.map_error(fn(_) { parse.CantParseRow(0, a, "Can't parse to int") })
  })
  |> parse.column(Ok)
  |> parse.set_col_sep(col_sep)
  |> parse.set_row_sep(row_sep)
  |> parse.set_escaper(escaper)
}

pub fn default_normal_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    )

  assert parsed == Ok(#(normal_data, []))
    as "Default parameters, normal data test"
}

pub fn default_column_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,\"This is a pretty good library, don't you think?\"\nBartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    )

  assert parsed == Ok(#(column_separator_data(col_sep), []))
    as "Default parameters, column separator data test"
}

pub fn default_row_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,\"It should be able to, right?\"\nBartholemew,24,\"Maybe column separators,\nbut what about row separators?\"",
    )

  assert parsed == Ok(#(row_separator_data(row_sep), []))
    as "Default parameters, row separator data test"
}

pub fn default_escaper_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"\nAlex,23,What are escapers?\nBartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    )

  assert parsed == Ok(#(escaper_data(esc), []))
    as "Default parameters, escaper data test"
}

// Custom column separator tests
pub fn custom_col_normal_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex|23|This is a pretty cool library\nBartholemew|24|Yeah I agree",
    )

  assert parsed == Ok(#(normal_data, []))
    as "Custom column separator, normal data test"
}

pub fn custom_col_column_separator_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex|23|This is a pretty good library, don't you think?\nBartholemew|24|\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try | this. heh\"",
    )

  assert parsed == Ok(#(column_separator_data(col_sep), []))
    as "Custom column separator, column separator data test"
}

pub fn custom_col_row_separator_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex|23|It should be able to, right?\nBartholemew|24|\"Maybe column separators,\nbut what about row separators?\"",
    )

  assert parsed == Ok(#(row_separator_data(row_sep), []))
    as "Custom column separator, row separator data test"
}

pub fn custom_col_escaper_test() {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Bartholemew|24|Huh, it worked. Now only escapers remain.\nAlex|23|What are escapers?\nBartholemew|24|\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    )

  assert parsed == Ok(#(escaper_data(esc), []))
    as "Custom column separator, escaper data test"
}

// Custom row separator tests
pub fn custom_row_normal_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,This is a pretty cool library|Bartholemew,24,Yeah I agree",
    )

  assert parsed == Ok(#(normal_data, []))
    as "Custom row separator, normal data test"
}

pub fn custom_row_column_separator_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,\"This is a pretty good library, don't you think?\"|Bartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    )

  assert parsed == Ok(#(column_separator_data(col_sep), []))
    as "Custom row separator, column separator data test"
}

pub fn custom_row_row_separator_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,\"It should be able to, right?\"|Bartholemew,24,\"Maybe column separators,|but what about row separators?\"",
    )

  assert parsed == Ok(#(row_separator_data(row_sep), []))
    as "Custom row separator, row separator data test"
}

pub fn custom_row_escaper_test() {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"|Alex,23,What are escapers?|Bartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    )

  assert parsed == Ok(#(escaper_data(esc), []))
    as "Custom row separator, escaper data test"
}

// Custom escaper tests
pub fn custom_esc_normal_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    )

  assert parsed == Ok(#(normal_data, [])) as "Custom escaper, normal data test"
}

pub fn custom_esc_column_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,'This is a pretty good library, don''t you think?'\nBartholemew,24,'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try , this. heh'",
    )

  assert parsed == Ok(#(column_separator_data(col_sep), []))
    as "Custom escaper, column separator data test"
}

pub fn custom_esc_row_separator_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex,23,'It should be able to, right?'\nBartholemew,24,'Maybe column separators,\nbut what about row separators?'",
    )

  assert parsed == Ok(#(row_separator_data(row_sep), []))
    as "Custom escaper, row separator data test"
}

pub fn custom_esc_escaper_test() {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Bartholemew,24,'Huh, it worked. Now only escapers remain.'\nAlex,23,What are escapers?\nBartholemew,24,'They''re what wrap a value if it contains reserved elements. Right now, it''s '''",
    )

  assert parsed == Ok(#(escaper_data(esc), []))
    as "Custom escaper, escaper data test"
}

// Combined tests
pub fn combined_normal_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex|23|This is a pretty cool library;Bartholemew|24|Yeah I agree",
    )

  assert parsed == Ok(#(normal_data, []))
    as "All custom parameters, normal data test"
}

pub fn combined_column_separator_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex|23|'This is a pretty good library, don''t you think?';Bartholemew|24|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'",
    )

  assert parsed == Ok(#(column_separator_data(col_sep), []))
    as "All custom parameters, column separator data test"
}

pub fn combined_row_separator_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Alex|23|It should be able to, right?;Bartholemew|24|'Maybe column separators,;but what about row separators?'",
    )

  assert parsed == Ok(#(row_separator_data(row_sep), []))
    as "All custom parameters, row separator data test"
}

pub fn combined_escaper_test() {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.parse(
      "Bartholemew|24|Huh, it worked. Now only escapers remain.;Alex|23|What are escapers?;Bartholemew|24|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''",
    )

  assert parsed == Ok(#(escaper_data(esc), []))
    as "All custom parameters, escaper data test"
}
