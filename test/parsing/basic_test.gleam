import mesv/parse.{DataNonDuplicatedEscapers, DataUnescapedEscapers, Text}
import mesv_test

pub fn default_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == mesv_test.expected_normal_data()
    as "Parsing default parameters | Normal"
}

pub fn whitespace_test() -> Nil {
  let parsed =
    mesv_test.row_data_parser(",", "\n", "\"")
    |> parse.run(Text(
      "Alex,23,  This is a pretty cool library  \nBartholemew, 24,Yeah I agree",
    ))

  assert parsed == mesv_test.expected_normal_data()
    as "Parsing default parameters | Trimming whitespace"
}

pub fn bad_escapers_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Adam,23,Likes to \"mess\" with parsers\n"
      <> "Bob,45,\"Doesn't understand that \"\"\"internal escapers\"\"\" should be duplicated, not triplicated\"",
    ))

  // This should throw errors. I need to restructure the error handling of parsing.
  assert parsed
    == [
      Error(DataUnescapedEscapers("Likes to \"mess\" with parsers")),
      Error(DataNonDuplicatedEscapers(
        "\"Doesn't understand that \"\"\"internal escapers\"\"\" should be duplicated, not triplicated\"",
      )),
    ]
    as "Parsing default parameters | Odd number of escapers"
}

pub fn escaped_whitespace_test() -> Nil {
  let col_sep = ","
  let parsed =
    mesv_test.row_data_parser(col_sep, "\n", "\"")
    |> parse.run(Text(
      "Alex,23,\"   This is a pretty good library, don't you think?   \"\nBartholemew,24,\" Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing default parameters | Trimming escaped whitespace"
}

pub fn padded_escaped_cell_test() -> Nil {
  let col_sep = ","
  let parsed =
    mesv_test.row_data_parser(col_sep, "\n", "\"")
    |> parse.run(Text(
      "Alex,23,  \"This is a pretty good library, don't you think?   \" \n   Bartholemew,24, \" Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing default parameters | Trimming escaped whitespace"
}

pub fn default_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,\"This is a pretty good library, don't you think?\"\nBartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing default parameters | Column separator"
}

pub fn default_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,\"It should be able to, right?\"\nBartholemew,24,\"Maybe column separators,\nbut what about row separators?\"",
    ))

  assert parsed == mesv_test.expected_row_separator_data(row_sep)
    as "Parsing default parameters | Row separator"
}

pub fn default_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"\nAlex,23,What are escapers?\nBartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    ))

  assert parsed == mesv_test.expected_escaper_data(esc)
    as "Parsing default parameters | Escaper"
}

// Custom column separator tests
pub fn custom_col_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex|23|This is a pretty cool library\nBartholemew|24|Yeah I agree",
    ))

  assert parsed == mesv_test.expected_normal_data()
    as "Parsing custom column separator | Normal"
}

pub fn custom_col_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex|23|This is a pretty good library, don't you think?\nBartholemew|24|\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try | this. heh\"",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing custom column separator | Column separator"
}

pub fn custom_col_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex|23|It should be able to, right?\nBartholemew|24|\"Maybe column separators,\nbut what about row separators?\"",
    ))

  assert parsed == mesv_test.expected_row_separator_data(row_sep)
    as "Parsing custom column separator | Row separator"
}

pub fn custom_col_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Bartholemew|24|Huh, it worked. Now only escapers remain.\nAlex|23|What are escapers?\nBartholemew|24|\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    ))

  assert parsed == mesv_test.expected_escaper_data(esc)
    as "Parsing custom column separator | Escaper"
}

// Custom row separator tests
pub fn custom_row_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,This is a pretty cool library|Bartholemew,24,Yeah I agree",
    ))

  assert parsed == mesv_test.expected_normal_data()
    as "Parsing custom row separator | Normal"
}

pub fn custom_row_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,\"This is a pretty good library, don't you think?\"|Bartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\"",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing custom row separator | Column separator"
}

pub fn custom_row_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,\"It should be able to, right?\"|Bartholemew,24,\"Maybe column separators,|but what about row separators?\"",
    ))

  assert parsed == mesv_test.expected_row_separator_data(row_sep)
    as "Parsing custom row separator | Row separator"
}

pub fn custom_row_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"|Alex,23,What are escapers?|Bartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\"",
    ))

  assert parsed == mesv_test.expected_escaper_data(esc)
    as "Parsing custom row separator | Escaper"
}

// Custom escaper tests
pub fn custom_esc_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == mesv_test.expected_normal_data()
    as "Parsing custom escaper | Normal"
}

pub fn custom_esc_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,'This is a pretty good library, don''t you think?'\nBartholemew,24,'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try , this. heh'",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing custom escaper | Column separator"
}

pub fn custom_esc_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex,23,'It should be able to, right?'\nBartholemew,24,'Maybe column separators,\nbut what about row separators?'",
    ))

  assert parsed == mesv_test.expected_row_separator_data(row_sep)
    as "Parsing custom escaper | Row separator"
}

pub fn custom_esc_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Bartholemew,24,'Huh, it worked. Now only escapers remain.'\nAlex,23,What are escapers?\nBartholemew,24,'They''re what wrap a value if it contains reserved elements. Right now, it''s '''",
    ))

  assert parsed == mesv_test.expected_escaper_data(esc)
    as "Parsing custom escaper | Escaper"
}

// Combined tests
pub fn combined_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex|23|This is a pretty cool library;Bartholemew|24|Yeah I agree",
    ))

  assert parsed == mesv_test.expected_normal_data()
    as "Parsing combined | Normal"
}

pub fn combined_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex|23|'This is a pretty good library, don''t you think?';Bartholemew|24|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'",
    ))

  assert parsed == mesv_test.expected_column_separator_data(col_sep)
    as "Parsing combined | Column separator"
}

pub fn combined_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Alex|23|It should be able to, right?;Bartholemew|24|'Maybe column separators,;but what about row separators?'",
    ))

  assert parsed == mesv_test.expected_row_separator_data(row_sep)
    as "Parsing combined | Row separator"
}

pub fn combined_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.run(Text(
      "Bartholemew|24|Huh, it worked. Now only escapers remain.;Alex|23|What are escapers?;Bartholemew|24|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''",
    ))

  assert parsed == mesv_test.expected_escaper_data(esc)
    as "Parsing combined | Escaper"
}
