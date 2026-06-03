import format.{type Formatter}
import gleam/int
import mesv_test.{type RowData, RowData}

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

pub fn default_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.normal_data())

  assert formatted
    == "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Normal"
}

pub fn default_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.column_separator_data(col_sep))

  assert formatted
    == "Alex,23,\"This is a pretty good library, don't you think?\"\nBartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\""
    as "Formatting default parameters | Column separator"
}

pub fn default_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.row_separator_data(row_sep))

  assert formatted
    == "Alex,23,\"It should be able to, right?\"\nBartholemew,24,\"Maybe column separators,\nbut what about row separators?\""
    as "Formatting default parameters | Row separator"
}

pub fn default_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.escaper_data(esc))

  assert formatted
    == "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"\nAlex,23,What are escapers?\nBartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Formatting default parameters | Escaper"
}

// Custom column separator tests
pub fn custom_col_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.normal_data())

  assert formatted
    == "Alex|23|This is a pretty cool library\nBartholemew|24|Yeah I agree"
    as "Formatting custom column separator | Normal"
}

pub fn custom_col_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.column_separator_data(col_sep))

  assert formatted
    == "Alex|23|This is a pretty good library, don't you think?\nBartholemew|24|\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try | this. heh\""
    as "Formatting custom column separator | Column separator"
}

pub fn custom_col_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.row_separator_data(row_sep))

  assert formatted
    == "Alex|23|It should be able to, right?\nBartholemew|24|\"Maybe column separators,\nbut what about row separators?\""
    as "Formatting custom column separator | Row separator"
}

pub fn custom_col_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.escaper_data(esc))

  assert formatted
    == "Bartholemew|24|Huh, it worked. Now only escapers remain.\nAlex|23|What are escapers?\nBartholemew|24|\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Formatting custom column separator | Escaper"
}

// Custom row separator tests
pub fn custom_row_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.normal_data())

  assert formatted
    == "Alex,23,This is a pretty cool library|Bartholemew,24,Yeah I agree"
    as "Formatting custom row separator | Normal"
}

pub fn custom_row_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.column_separator_data(col_sep))

  assert formatted
    == "Alex,23,\"This is a pretty good library, don't you think?\"|Bartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\""
    as "Formatting custom row separator | Column separator"
}

pub fn custom_row_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.row_separator_data(row_sep))

  assert formatted
    == "Alex,23,\"It should be able to, right?\"|Bartholemew,24,\"Maybe column separators,|but what about row separators?\""
    as "Formatting custom row separator | Row separator"
}

pub fn custom_row_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "|"
  let esc = "\""
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.escaper_data(esc))

  assert formatted
    == "Bartholemew,24,\"Huh, it worked. Now only escapers remain.\"|Alex,23,What are escapers?|Bartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Formatting custom row separator | Escaper"
}

// Custom escaper tests
pub fn custom_esc_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.normal_data())

  assert formatted
    == "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting custom escaper | Normal"
}

pub fn custom_esc_column_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.column_separator_data(col_sep))

  assert formatted
    == "Alex,23,'This is a pretty good library, don''t you think?'\nBartholemew,24,'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try , this. heh'"
    as "Formatting custom escaper | Column separator"
}

pub fn custom_esc_row_separator_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.row_separator_data(row_sep))

  assert formatted
    == "Alex,23,'It should be able to, right?'\nBartholemew,24,'Maybe column separators,\nbut what about row separators?'"
    as "Formatting custom escaper | Row separator"
}

pub fn custom_esc_escaper_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.escaper_data(esc))

  assert formatted
    == "Bartholemew,24,'Huh, it worked. Now only escapers remain.'\nAlex,23,What are escapers?\nBartholemew,24,'They''re what wrap a value if it contains reserved elements. Right now, it''s '''"
    as "Formatting custom escaper | Escaper"
}

// Combined tests
pub fn combined_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.normal_data())

  assert formatted
    == "Alex|23|This is a pretty cool library;Bartholemew|24|Yeah I agree"
    as "Formatting combined | Normal"
}

pub fn combined_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.column_separator_data(col_sep))

  assert formatted
    == "Alex|23|'This is a pretty good library, don''t you think?';Bartholemew|24|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'"
    as "Formatting combined | Column separator"
}

pub fn combined_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.row_separator_data(row_sep))

  assert formatted
    == "Alex|23|It should be able to, right?;Bartholemew|24|'Maybe column separators,;but what about row separators?'"
    as "Formatting combined | Row separator"
}

pub fn combined_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    build_test_unit_formatter(format_row_data, col_sep, row_sep, esc)
    |> format.format(mesv_test.escaper_data(esc))

  assert formatted
    == "Bartholemew|24|Huh, it worked. Now only escapers remain.;Alex|23|What are escapers?;Bartholemew|24|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''"
    as "Formatting combined | Escaper"
}
