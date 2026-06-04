import gleam/int
import gleam/list
import mesv
import mesv/parse.{type Parser, MalformedCell}
import mesv_test.{type RowData, RowData}

fn expected_normal_data() -> List(Result(RowData, b)) {
  mesv_test.normal_data() |> list.map(Ok)
}

fn expected_column_separator_data(col_sep: String) -> List(Result(RowData, b)) {
  mesv_test.column_separator_data(col_sep) |> list.map(Ok)
}

fn expected_row_separator_data(row_sep: String) -> List(Result(RowData, b)) {
  mesv_test.row_separator_data(row_sep) |> list.map(Ok)
}

fn expected_escaper_data(esc: String) -> List(Result(RowData, b)) {
  mesv_test.escaper_data(esc) |> list.map(Ok)
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
  |> parse.column(int.parse)
  |> parse.column(Ok)
  |> parse.set_col_sep(col_sep)
  |> parse.set_row_sep(row_sep)
  |> parse.set_escaper(escaper)
}

pub fn default_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    )

  assert parsed == Ok(expected_normal_data())
    as "Parsing default parameters | Normal"
}

pub fn whitespace_test() -> Nil {
  let parsed =
    build_test_unit_parser(",", "\n", "\"")
    |> parse.run(
      "Alex,23,  This is a pretty cool library  \nBartholemew, 24,Yeah I agree",
    )

  assert parsed == Ok(expected_normal_data())
    as "Parsing default parameters | Trimming whitespace"
}

pub fn bad_escapers_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Adam,23,Likes to \"mess\" with parsers\n"
      <> "Bob,45,\"Doesn't understand that \"\"\"internal escapers\"\"\" should be duplicated, not triplicated\"",
    )

  // This should throw errors. I need to restructure the error handling of parsing.
  assert parsed
    == Ok([
      Error(MalformedCell(
        "Likes to \"mess\" with parsers",
        "Unescaped internal escapers",
      )),
      Error(MalformedCell(
        "\"Doesn't understand that \"\"\"internal escapers\"\"\" should be duplicated, not triplicated\"",
        "Wrongly duplicated internal escapers",
      )),
    ])
    as "Parsing default parameters | Odd number of escapers"
}

pub fn escaped_whitespace_test() -> Nil {
  let col_sep = ","
  let parsed =
    build_test_unit_parser(col_sep, "\n", "\"")
    |> parse.run(
      "Alex,23,\"   This is a pretty good library, don't you think?   \"\nBartholemew,24,\" Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing default parameters | Trimming escaped whitespace"
}

pub fn padded_escaped_cell_test() -> Nil {
  let col_sep = ","
  let parsed =
    build_test_unit_parser(col_sep, "\n", "\"")
    |> parse.run(
      "Alex,23,  \"This is a pretty good library, don't you think?   \" \n   Bartholemew,24, \" Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing default parameters | Trimming escaped whitespace"
}

pub fn default_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,\"This is a pretty good library, don't you think?\"\nBartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing default parameters | Column separator"
}

pub fn default_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,\"It should be able to, right?\"\nBartholemew,24,\"Maybe column separators,\nbut what about row separators?\"",
    )

  assert parsed == Ok(expected_row_separator_data(row_sep))
    as "Parsing default parameters | Row separator"
}

pub fn default_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"\nAlex,23,What are escapers?\nBartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    )

  assert parsed == Ok(expected_escaper_data(esc))
    as "Parsing default parameters | Escaper"
}

// Custom column separator tests
pub fn custom_col_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex|23|This is a pretty cool library\nBartholemew|24|Yeah I agree",
    )

  assert parsed == Ok(expected_normal_data())
    as "Parsing custom column separator | Normal"
}

pub fn custom_col_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex|23|This is a pretty good library, don't you think?\nBartholemew|24|\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try | this. heh\"",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing custom column separator | Column separator"
}

pub fn custom_col_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex|23|It should be able to, right?\nBartholemew|24|\"Maybe column separators,\nbut what about row separators?\"",
    )

  assert parsed == Ok(expected_row_separator_data(row_sep))
    as "Parsing custom column separator | Row separator"
}

pub fn custom_col_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Bartholemew|24|Huh, it worked. Now only escapers remain.\nAlex|23|What are escapers?\nBartholemew|24|\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    )

  assert parsed == Ok(expected_escaper_data(esc))
    as "Parsing custom column separator | Escaper"
}

// Custom row separator tests
pub fn custom_row_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,This is a pretty cool library|Bartholemew,24,Yeah I agree",
    )

  assert parsed == Ok(expected_normal_data())
    as "Parsing custom row separator | Normal"
}

pub fn custom_row_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,\"This is a pretty good library, don't you think?\"|Bartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing custom row separator | Column separator"
}

pub fn custom_row_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,\"It should be able to, right?\"|Bartholemew,24,\"Maybe column separators,|but what about row separators?\"",
    )

  assert parsed == Ok(expected_row_separator_data(row_sep))
    as "Parsing custom row separator | Row separator"
}

pub fn custom_row_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"|Alex,23,What are escapers?|Bartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    )

  assert parsed == Ok(expected_escaper_data(esc))
    as "Parsing custom row separator | Escaper"
}

// Custom escaper tests
pub fn custom_esc_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    )

  assert parsed == Ok(expected_normal_data())
    as "Parsing custom escaper | Normal"
}

pub fn custom_esc_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,'This is a pretty good library, don''t you think?'\nBartholemew,24,'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try , this. heh'",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing custom escaper | Column separator"
}

pub fn custom_esc_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex,23,'It should be able to, right?'\nBartholemew,24,'Maybe column separators,\nbut what about row separators?'",
    )

  assert parsed == Ok(expected_row_separator_data(row_sep))
    as "Parsing custom escaper | Row separator"
}

pub fn custom_esc_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Bartholemew,24,'Huh, it worked. Now only escapers remain.'\nAlex,23,What are escapers?\nBartholemew,24,'They''re what wrap a value if it contains reserved elements. Right now, it''s '''",
    )

  assert parsed == Ok(expected_escaper_data(esc))
    as "Parsing custom escaper | Escaper"
}

// Combined tests
pub fn combined_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex|23|This is a pretty cool library;Bartholemew|24|Yeah I agree",
    )

  assert parsed == Ok(expected_normal_data()) as "Parsing combined | Normal"
}

pub fn combined_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex|23|'This is a pretty good library, don''t you think?';Bartholemew|24|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'",
    )

  assert parsed == Ok(expected_column_separator_data(col_sep))
    as "Parsing combined | Column separator"
}

pub fn combined_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Alex|23|It should be able to, right?;Bartholemew|24|'Maybe column separators,;but what about row separators?'",
    )

  assert parsed == Ok(expected_row_separator_data(row_sep))
    as "Parsing combined | Row separator"
}

pub fn combined_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.run(
      "Bartholemew|24|Huh, it worked. Now only escapers remain.;Alex|23|What are escapers?;Bartholemew|24|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''",
    )

  assert parsed == Ok(expected_escaper_data(esc))
    as "Parsing combined | Escaper"
}
