import mesv/format
import mesv_test

pub fn default_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.build_test_unit_formatter(
      mesv_test.format_row_data,
      col_sep,
      row_sep,
      esc,
    )
    |> format.preprocess([#("test", "will it work?")])
    |> format.then(mesv_test.normal_data())

  assert formatted
    == "---\ntest:will it work?\n---\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree"
    as "Formatting default parameters | Metadata :)"
}
