import gleam/int
import gleam/option.{None}
import mesv/format
import mesv/stream
import mesv_test.{type RowData}

pub fn default_normal_test() -> Nil {
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_collect()

  assert formatted
    == "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatter column builder | Normal"
}

pub fn default_column_separator_test() -> Nil {
  let col_sep = ","
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.preprocess([])
    |> format.then_run(
      stream.from_list(mesv_test.column_separator_data(col_sep)),
    )
    |> format.then_collect()

  assert formatted
    == "Name,Age,Comment\nAlex,23,\"This is a pretty good library, don't you think?\""
    <> "\nBartholemew,24,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\""
    as "Formatter column builder | Column separator"
}

pub fn default_row_separator_test() -> Nil {
  let row_sep = "\n"
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_row_sep(row_sep)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.row_separator_data(row_sep)))
    |> format.then_collect()

  assert formatted
    == "Name,Age,Comment\nAlex,23,\"It should be able to, right?\"\nBartholemew,24,\"Maybe column separators,\nbut what about row separators?\""
    as "Formatter column builder | Row separator"
}

pub fn default_escaper_test() -> Nil {
  let esc = "\""
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.escaper_data(esc)))
    |> format.then_collect()

  assert formatted
    == "Name,Age,Comment\nBartholemew,24,\"Huh, it worked. Now only escapers remain.\"\nAlex,23,What are escapers?\nBartholemew,24,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Formatter column builder | Escaper"
}

pub fn rearranged_normal_test() -> Nil {
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_collect()

  assert formatted
    == "Age,Name,Comment\n23,Alex,This is a pretty cool library\n24,Bartholemew,Yeah I agree"
    as "Formatter column builder | Normal data rearranged"
}

pub fn rearranged_column_separator_test() -> Nil {
  let col_sep = ","
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.preprocess([])
    |> format.then_run(
      stream.from_list(mesv_test.column_separator_data(col_sep)),
    )
    |> format.then_collect()

  assert formatted
    == "Age,Name,Comment\n23,Alex,\"This is a pretty good library, don't you think?\""
    <> "\n24,Bartholemew,\"Yeah, it's pretty good, but are you sure it can handle escaping separators? Try , this. heh\""
    as "Formatter column builder | Column separator data rearranged"
}

pub fn rearranged_row_separator_test() -> Nil {
  let row_sep = "\n"
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_row_sep(row_sep)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.row_separator_data(row_sep)))
    |> format.then_collect()

  assert formatted
    == "Age,Name,Comment\n23,Alex,\"It should be able to, right?\"\n24,Bartholemew,\"Maybe column separators,\nbut what about row separators?\""
    as "Formatter column builder | Row separator data rearranged"
}

pub fn rearranged_escaper_test() -> Nil {
  let esc = "\""
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.escaper_data(esc)))
    |> format.then_collect()

  assert formatted
    == "Age,Name,Comment\n24,Bartholemew,\"Huh, it worked. Now only escapers remain.\"\n23,Alex,What are escapers?\n24,Bartholemew,\"They're what wrap a value if it contains reserved elements. Right now, it's \"\"\""
    as "Formatter column builder | Escaper data rearranged"
}

pub fn custom_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_collect()

  assert formatted
    == "Name|Age|Comment;Alex|23|This is a pretty cool library;Bartholemew|24|Yeah I agree"
    as "Formatter column builder | Custom, normal data"
}

pub fn custom_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(
      stream.from_list(mesv_test.column_separator_data(col_sep)),
    )
    |> format.then_collect()

  assert formatted
    == "Name|Age|Comment;Alex|23|'This is a pretty good library, don''t you think?';"
    <> "Bartholemew|24|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'"
    as "Formatter column builder | Custom, column separator data"
}

pub fn custom_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.row_separator_data(row_sep)))
    |> format.then_collect()

  assert formatted
    == "Name|Age|Comment;Alex|23|It should be able to, right?;Bartholemew|24|'Maybe column separators,;but what about row separators?'"
    as "Formatter column builder | Custom, row separator data"
}

pub fn custom_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.escaper_data(esc)))
    |> format.then_collect()

  assert formatted
    == "Name|Age|Comment;Bartholemew|24|Huh, it worked. Now only escapers remain.;Alex|23|What are escapers?;Bartholemew|24|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''"
    as "Formatter column builder | Custom, escaper data"
}

pub fn custom_rearranged_normal_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_collect()

  assert formatted
    == "Age|Name|Comment;23|Alex|This is a pretty cool library;24|Bartholemew|Yeah I agree"
    as "Formatter column builder | Custom, normal data rearranged"
}

pub fn custom_rearranged_column_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(
      stream.from_list(mesv_test.column_separator_data(col_sep)),
    )
    |> format.then_collect()

  assert formatted
    == "Age|Name|Comment;23|Alex|'This is a pretty good library, don''t you think?';"
    <> "24|Bartholemew|'Yeah, it''s pretty good, but are you sure it can handle escaping separators? Try | this. heh'"
    as "Formatter column builder | Custom, column separator data rearranged"
}

pub fn custom_rearranged_row_separator_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.row_separator_data(row_sep)))
    |> format.then_collect()

  assert formatted
    == "Age|Name|Comment;23|Alex|It should be able to, right?;24|Bartholemew|'Maybe column separators,;but what about row separators?'"
    as "Formatter column builder | Custom, row separator data rearranged"
}

pub fn custom_rearranged_escaper_test() -> Nil {
  let col_sep = "|"
  let row_sep = ";"
  let esc = "'"
  let formatted =
    format.init()
    |> format.column("Age", None, fn(row: RowData) {
      row.age |> int.to_string()
    })
    |> format.column("Name", None, fn(row: RowData) { row.name })
    |> format.column("Comment", None, fn(row: RowData) { row.comment })
    |> format.set_col_sep(col_sep)
    |> format.set_row_sep(row_sep)
    |> format.set_escaper(esc)
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.escaper_data(esc)))
    |> format.then_collect()

  assert formatted
    == "Age|Name|Comment;24|Bartholemew|Huh, it worked. Now only escapers remain.;23|Alex|What are escapers?;24|Bartholemew|'They''re what wrap a value if it contains reserved elements. Right now, it''s '''"
    as "Formatter column builder | Custom, escaper data rearranged"
}
