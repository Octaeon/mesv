pub type ParsingError

pub opaque type Parser(a) {
  Parser(
    column_separator: String,
    row_separator: String,
    parse: fn(List(String)) -> Result(#(a, List(String)), ParsingError),
  )
}

pub fn parsed(f: fn(a) -> b) -> fn(a) -> b {
  f
}

pub fn build(f: fn(a) -> b) -> Parser(fn(a) -> b) {
  Parser(
    column_separator: ",",
    row_separator: "\n",
    parse: fn(tokens: List(String)) -> Result(
      #(fn(a) -> b, List(String)),
      ParsingError,
    ) {
      Ok(#(f, tokens))
    },
  )
}
