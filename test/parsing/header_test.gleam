import gleam/string
import mesv/parse.{
  DataUnescapedEscapers, FailedHeaderParsing, HeadersMismatch, Ignore,
  InOrderExact, InOrderMustPass, Text,
}
import mesv/util
import mesv_test

pub fn old_header_behaviour_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.expect_headers(["Name", "Age", "Comment"])
    |> parse.preprocess(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Old header behaviour"
}

pub fn old_header_behaviour_error_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.expect_headers(["Name", "Age", "Comment"])
    |> parse.preprocess(Text(
      "Name,Age,comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed
    == Error(
      HeadersMismatch(["Name", "Age", "comment"], [Ok(0), Ok(1), Error(Nil)]),
    )
    as "Parsing default parameters | Old header behaviour, expected error"
}

pub fn default_skip_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Ignore)
    |> parse.preprocess(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, Skip correct CSV"
}

pub fn default_skip_empty_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Ignore)
    |> parse.preprocess(Text(
      "\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data()) as
    // When Ignoring a row, no need to check if there are enough columns or anything
    "Parsing default parameters | Headers, Ignore empty header row"
}

pub fn default_skip_empty_row_strict_columns_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Ignore)
    |> parse.set_strict_columns()
    |> parse.preprocess(Text(
      "\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data()) as
    // When Ignoring a row, no need to check if there are enough columns or anything
    "Parsing default parameters | Headers, Ignore empty header row"
}

pub fn default_skip_malformed_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Ignore)
    |> parse.preprocess(Text(
      "this,header,row,has,way,too,many,elements,and \"they're not\" even properly escaped!, "
      <> "but it will be skipped anyways\n"
      <> "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed
    == Error(
      FailedHeaderParsing(DataUnescapedEscapers(
        "and \"they're not\" even properly escaped!",
      )),
    )
    as
    // I have decided to process the first row even if the user specified to ignore it, and if its'
    // malformed, to throw an error.
    "Parsing default parameters | Headers, Ignore don't allow malformed values"
}

pub fn default_ordered_exact_pass_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(InOrderExact(["Name", "Age", "Comment"]))
    |> parse.preprocess(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, InOrderExact pass"
}

pub fn default_ordered_exact_fail_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(InOrderExact(["Name", "Age", "Comment"]))
    |> parse.preprocess(Text(
      "Name,Age,comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed
    == Error(
      HeadersMismatch(["Name", "Age", "comment"], [Ok(0), Ok(1), Error(Nil)]),
    )
    as "Parsing default parameters | Headers, InOrderExact fail"
}

pub fn default_ordered_match_pass_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      InOrderMustPass([
        util.new("Name", string.lowercase, fn(first, second) { first == second }),
        util.new("Age", string.lowercase, fn(first, second) { first == second }),
        util.new("Comment", string.lowercase, fn(first, second) {
          first == second
        }),
      ]),
    )
    |> parse.preprocess(Text(
      "NaMe,AgE,CoMmEnT\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, InOrderMustPass pass"
}

pub fn default_ordered_match_fail_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      InOrderMustPass([
        util.new("Name", string.lowercase, fn(first, second) { first == second }),
        util.new("Age", string.lowercase, fn(first, second) { first == second }),
        util.new("Comment", string.lowercase, fn(first, second) {
          first == second
        }),
      ]),
    )
    |> parse.preprocess(Text(
      "name.,Age,COMMENT\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed
    == Error(
      HeadersMismatch(["name.", "Age", "COMMENT"], [Error(Nil), Ok(1), Ok(2)]),
    )
    as
    // Impossible to test for equality between objects containing functions
    "Parsing default parameters | Headers, InOrderMustPass fail"
}

pub fn default_header_expectation_transform_lowercase_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      InOrderExact(["Name", "Age", "Comment"])
      |> parse.transform_headers(string.lowercase),
    )
    |> parse.preprocess(Text(
      "NAME,AGE,COMMENT\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))
    |> parse.then_run()
    |> parse.then_collect_data()

  assert parsed == Ok(mesv_test.expected_normal_data()) as
    // Impossible to test for equality between objects containing functions
    "Parsing default parameters | Headers, transform_headers InOrderExact make lowercase"
}
