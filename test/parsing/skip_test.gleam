import gleam/int
import gleam/list
import gleam/string
import mesv
import mesv/parse.{type Parser, Text}

type SimpleRow {
  SimpleRow(date: String, time: String, event: String)
}

fn make_test_parser(col_sep, row_sep, esc) -> Parser(SimpleRow, Nil) {
  parse.build({
    use date_time: #(String, String) <- mesv.parsed
    // use d: String <- mesv.parsed

    use event: String <- mesv.parsed

    SimpleRow(date_time.0, date_time.1, event)
  })
  |> parse.skip_(2)
  |> parse.column(fn(t) {
    string.split_once(t, on: "T")
    // Ok(t)
  })
  |> parse.skip_(3)
  |> parse.column(Ok)
  |> parse.set_col_sep(col_sep)
  |> parse.set_row_sep(row_sep)
  |> parse.set_escaper(esc)
}

fn example_data(col_sep, row_sep, _esc) -> String {
  ["the user entered", "user left", "user gave a bad review"]
  |> list.index_map(fn(row, index) {
    let hour =
      string.join(
        [
          "16",
          int.to_string(index) <> int.to_string(index * 2 + 3),
          { 40 - index * 3 }
            |> int.clamp(min: 0, max: 60)
            |> int.to_string()
            |> string.pad_end(to: 2, with: "0"),
        ],
        with: ":",
      )
    [
      "garbage",
      "more",
      "2026-04-11T" <> hour <> "Z",
      "http headers",
      "http response",
      "status code",
      row,
    ]
  })
  |> list.map(string.join(_, with: col_sep))
  |> string.join(with: row_sep)
}

pub fn default_normal_test() -> Nil {
  let col_sep = ","
  let row_sep = "\n"
  let esc = "\""
  let data = example_data(col_sep, row_sep, esc)
  let parsed =
    make_test_parser(col_sep, row_sep, esc)
    |> parse.preprocess(Text(data))
    |> parse.then()
    |> parse.then_collect_data()

  assert parsed
    == Ok([
      Ok(SimpleRow("2026-04-11", "16:03:40Z", "the user entered")),
      Ok(SimpleRow("2026-04-11", "16:15:37Z", "user left")),
      Ok(SimpleRow("2026-04-11", "16:27:34Z", "user gave a bad review")),
    ])
    as "Parsing default parameters | Column skip, basic"
}
