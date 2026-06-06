import mesv/format
import mesv_test.{RowData}

pub fn default_basic_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([#("first", "test")])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == "---\nfirst:test\n---\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Metadata, basic"
}

pub fn default_escape_all_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.set_escape_all(True)
    |> format.preprocess([#("we're innocent", "don't escape us!")])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == "---\n\"we're innocent\":\"don't escape us!\"\n---\n\"Alex\",\"23\",\"This is a pretty cool library\"\n\"Bartholemew\",\"24\",\"Yeah I agree\""
    as "Formatting default parameters | Metadata, basic"
}

pub fn default_multiple_line_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([
      #("this", "time"),
      #("I'm", "testing"),
      #("multiple", "line metadata."),
    ])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == "---\nthis:time\nI'm:testing\nmultiple:line metadata.\n---\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Metadata, multiple line"
}

pub fn default_escaped_key_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([
      #("doublequotes" <> esc <> " key", "no"),
      #("meta" <> meta_sep <> " key", "second value"),
      #("row" <> meta_sep <> "separators?", "I'm 'fraid *not*"),
    ])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == {
      "---\n\"doublequotes\"\" key\":no\n\"meta: key\":also no\n\"row\nseparators?\":I'm 'fraid *not*\n---\n"
      <> "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    }
    as "Formatting default parameters | Metadata, escaped keys"
}

pub fn default_escaped_value_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([
      #("first key", "illegal" <> esc <> "escaper" <> esc <> "smuggling"),
      #(
        "second key",
        meta_sep <> " - metadata separator smuggling is illegal for a reason",
      ),
      #("third", "row separators" <> row_sep <> "also no"),
    ])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == {
      "---\nfirst key:\"illegal\"\"escaper\"\"smuggling\"\nsecond key:\": - metadata separator smuggling is illegal for a reason\"\nthird:\"row separators\nalso no\"\n---\n"
      <> "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    }
    as "Formatting default parameters | Metadata, escaped values"
}

pub fn default_column_separator_metadata_key_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([
      #("column" <> col_sep <> " separators", "are allowed in metadata"),
    ])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == {
      "---\ncolumn, separators:are allowed in metadata\n---\n"
      <> "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    }
    as "Formatting default parameters | Metadata, column separators in keys"
}

pub fn default_column_separator_metadata_value_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([
      #("also in", "metadata " <> col_sep <> " values"),
    ])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == {
      "---\nalso in:metadata , values\n---\n"
      <> "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    }
    as "Formatting default parameters | Metadata, column separators in values"
}

pub fn default_metadata_separator_in_data_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let meta_sep = ":"
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_meta_sep(meta_sep)
    |> format.preprocess([
      #("the metadata", "doesn't matter here"),
    ])
    |> format.then([
      RowData(
        "Arson",
        2,
        "My parent's poor name decisions are not what's relevant here: whether this comment will be escaped or not does.",
      ),
    ])

  assert formatted
    == {
      "---\nthe metadata:doesn't matter here\n---\n"
      <> "Arson,2,My parent's poor name decisions are not what's relevant here: whether this comment will be escaped or not does."
    }
    as "Formatting default parameters | Metadata, metadata separator in CSV data"
}
