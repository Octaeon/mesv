import gleam/string
import mesv/parse.{
  ExpectedHeadersMismatch, HeadersMustContain, HeadersMustContainPassing,
  InOrderExact, InOrderMustPass, MalformedCell, Skip, Text,
}
import mesv_test

pub fn old_header_behaviour_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
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
    mesv_test.row_data_parser(col_sep, row_sep, esc)
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

pub fn default_skip_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Skip)
    |> parse.run(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, Skip correct CSV"
}

pub fn default_skip_empty_row_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Skip)
    |> parse.run(Text(
      "\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, Skip empty header row"
}

pub fn default_skip_malformed_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(Skip)
    |> parse.run(Text(
      "this,header,row,has,way,too,many,elements,and \"they're not\" even properly escaped!, but it will be skipped anyways\n"
      <> "Alex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data()) as
    // I'm not yet certain whether this is the kind of behaviour I want to happen, but if the user
    // states they want to "Skip" the first row, doesn't that imply they don't care about what's inside of it?
    // Maybe I should rename that option to "Ignore" - that would imply parsing the first row but ignoring its'
    // contents, not just jumping over it.
    "Parsing default parameters | Headers, Skip malformed header row"
}

pub fn default_ordered_exact_pass_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(InOrderExact(["Name", "Age", "Comment"]))
    |> parse.run(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

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
    as "Parsing default parameters | Headers, InOrderExact fail"
}

pub fn default_unordered_exact_pass_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      HeadersMustContain(["Comment", "Name", "Age"]),
    )
    |> parse.run(Text(
      "Name,Age,Comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, HeadersMustContain pass"
}

pub fn default_unordered_exact_fail_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      HeadersMustContain(["Comment", "Name", "Age"]),
    )
    |> parse.run(Text(
      "Name,Age,comment\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed
    == Error(
      ExpectedHeadersMismatch(HeadersMustContain(["Comment", "Name", "Age"]), [
        "Name",
        "Age",
        "comment",
      ]),
    )
    as "Parsing default parameters | Headers, HeadersMustContain fail"
}

pub fn default_ordered_match_pass_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      InOrderMustPass([
        fn(h) { string.lowercase(h) == "name" },
        fn(h) { string.lowercase(h) == "age" },
        fn(h) { string.lowercase(h) == "comment" },
      ]),
    )
    |> parse.run(Text(
      "NaMe,AgE,CoMmEnT\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

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
        fn(h) { string.lowercase(h) == "name" },
        fn(h) { string.lowercase(h) == "age" },
        fn(h) { string.lowercase(h) == "comment" },
      ]),
    )
    |> parse.run(Text(
      "name.,age.,comment.\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed != Ok(mesv_test.expected_normal_data()) as
    // Impossible to test for equality between objects containing functions
    "Parsing default parameters | Headers, InOrderMustPass fail"
}

pub fn default_unordered_match_pass_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      HeadersMustContainPassing([
        fn(h) { string.lowercase(h) == "name" },
        fn(h) { string.lowercase(h) == "age" },
        fn(h) { string.lowercase(h) == "comment" },
      ]),
    )
    |> parse.run(Text(
      "NaMe,CoMmEnT,AgE\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data())
    as "Parsing default parameters | Headers, HeadersMustContainPassing pass"
}

pub fn default_unordered_match_fail_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      HeadersMustContainPassing([
        fn(h) { string.lowercase(h) == "name" },
        fn(h) { string.lowercase(h) == "age" },
        fn(h) { string.lowercase(h) == "comment" },
      ]),
    )
    |> parse.run(Text(
      "name.,comment.,age.\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed != Ok(mesv_test.expected_normal_data()) as
    // Impossible to test for equality between objects containing functions
    "Parsing default parameters | Headers, HeadersMustContainPassing fail"
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
    |> parse.run(Text(
      "NAME,AGE,COMMENT\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data()) as
    // Impossible to test for equality between objects containing functions
    "Parsing default parameters | Headers, transform_headers InOrderExact make lowercase"
}

pub fn default_header_expectation_transform_trim_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let parsed =
    mesv_test.row_data_parser(col_sep, row_sep, esc)
    |> parse.set_expected_headers(
      HeadersMustContain(["Age", "Name", "Comment"])
      |> parse.transform_headers(fn(s) {
        s |> string.lowercase() |> string.trim()
      }),
    )
    |> parse.set_trim_whitespace(True, True)
    |> parse.run(Text(
      "name    ,age    ,\"  comment  \"\nAlex,23,This is a pretty cool library\nBartholemew,24,Yeah I agree",
    ))

  assert parsed == Ok(mesv_test.expected_normal_data()) as
    // Impossible to test for equality between objects containing functions
    "Parsing default parameters | Headers, transform_headers InOrderExact lowercase trim"
}
