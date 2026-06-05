import mesv/parse.{ExpectedHeadersMismatch, InOrderExact, Text}
import mesv_test

pub fn old_header_behaviour_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.expect_headers(["Name", "Age", "Comment"])
    |> parse.run(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Old header behaviour"
}

pub fn old_header_behaviour_error_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.build_test_unit_parser(col_sep, row_sep, esc)
    |> parse.expect_headers(["Name", "Age", "Comment"])
    |> parse.run(Text(
      "Name,Age,comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed
    == Error(
      ExpectedHeadersMismatch(InOrderExact(["Name", "Age", "Comment"]), [
        "Name",
        "Age",
        "comment",
      ]),
    )
    as "Parsing default parameters | Old header behaviour, expected error"
}
