import gleam/string
import mesv/format
import mesv_test

pub fn default_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let formatted =
    mesv_test.row_data_formatter(col_sep, row_sep, esc)
    |> format.set_headers(["Name", "Age", "Comment"])
    |> format.run(mesv_test.normal_data())

  assert string.split("", on: ":") == [""] as "String split behaviour"
}
