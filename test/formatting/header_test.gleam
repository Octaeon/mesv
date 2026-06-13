import mesv/format
import mesv/stream
import mesv_test

pub fn default_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_headers(["Name", "Age", "Comment"])
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_join(row_sep)

  assert formatted
    == "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Basic header behaviour"
}

pub fn default_whitespace_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_headers(["  Name  ", "  Age  ", "  Comment  "])
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_join(row_sep)

  assert formatted
    == "  Name  ,  Age  ,  Comment  \nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Expect whitespace preservation in headers"
}

pub fn default_normal_escaped_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_headers(["Name", "\"Age\"", "Comment"])
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_join(row_sep)

  assert formatted
    == "Name,\"\"\"Age\"\"\",Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Header escaping"
}

pub fn default_whitespace_escaped_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_headers(["  Name  ", "\"  Age  \"", "  Comment  "])
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_join(row_sep)

  assert formatted
    == "  Name  ,\"\"\"  Age  \"\"\",  Comment  \nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Expect whitespace preservation in headers inside escapers"
}

pub fn default_whitespace_around_escapers_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_headers(["  Name  ", "  \"Age\"  ", "  Comment  "])
    |> format.preprocess([])
    |> format.then_run(stream.from_list(mesv_test.normal_data()))
    |> format.then_join(row_sep)

  assert formatted
    == "  Name  ,\"  \"\"Age\"\"  \",  Comment  \nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Expect whitespace preservation in headers outside of escapers"
}
