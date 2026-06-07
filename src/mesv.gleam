//// A CSV parsing library that strongly enforces Data Integrity, allows for creation of both
//// a formatter (`fn(data) -> String`) and parser (`fn(String) -> data`) from the same
//// data type, and allows the user to add Frontmatter metadata to CSV files.
//// 
//// This root module is rather barren, as most of the relevant functionality is categorized
//// into the two modules, [`mesv/format`](mesv/format.html) and [`mesv/parse`](mesv/parse.html).
//// 
//// 
//// TODO : Create an analogue of the `parse` and `format` build functions that can build both
//// a formatter and parser at the same time.
//// 
//// To do so, create constant `primitives` like the ones from `gleam/json`, as well as functions
//// that operate on those primitives. Lastly, allow users to create their own, and make a helper
//// function in `mesv_test` that allows for easy testing of these functions, that they are their
//// own inverses (ie, that a primitive with two functions inside of it, `fn encode(a) -> String`
//// and `fn decode(String) -> a` satisfy the condition that `for every possible i,
//// i = decode(encode(i))`)

import gleam/list
import gleam/result

/// A subset of an identity function for 1-arity functions.
/// 
/// Meant to be used in the `build` function with `use` statements, like so:
/// ```gleam
/// mesv.parse.build({
///   use player <- mesv.parsed
///   use score <- mesv.parsed
///   #(player, score)
/// })
/// ```
/// To clarify, the above code is equivalent to:
/// ```gleam
/// mesv.parse.build({
///   fn(player) {
///     fn(score) {
///       #(player, score)
///     }
///   }
/// })
/// ```
/// 
pub fn parsed(f: fn(a) -> b) -> fn(a) -> b {
  f
}

pub type Mapping(a, b, e) {
  Mapping(
    get: fn(b) -> a,
    encode: fn(a) -> String,
    decode: fn(String) -> Result(a, e),
  )
}

pub type CellError(e) {
  NotEnoughTokens
  CellError(cell: String, error: e)
}

pub opaque type Builder(a, e) {
  Builder(
    column_separator: String,
    row_separator: String,
    escaper: String,
    metadata_separator: String,
    column_names: List(String),
    parse: fn(List(String)) -> Result(#(a, List(String)), e),
    format: fn() -> #(a, List(fn(a) -> String)),
  )
}

pub fn start(constructor: fn(a) -> b) -> Builder(fn(a) -> b, e) {
  Builder(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    metadata_separator: ":",
    column_names: [],
    parse: fn(tokens: List(String)) -> Result(#(fn(a) -> b, List(String)), e) {
      Ok(#(constructor, tokens))
    },
    format: fn() { #(constructor, []) },
  )
}

pub fn column(
  builder: Builder(fn(a) -> b, CellError(e)),
  mapping: Mapping(a, b, e),
) -> Builder(b, CellError(e)) {
  let Mapping(get, encode_token, decode_token) = mapping
  let Builder(
    column_separator,
    row_separator,
    escaper,
    metadata_separator,
    columns,
    parse,
    format,
  ) = builder

  Builder(
    column_separator,
    row_separator,
    escaper,
    metadata_separator,
    columns,
    parse: fn(tokens: List(String)) -> Result(#(b, List(String)), CellError(e)) {
      use #(constructor, remaining_tokens) <- result.try(parse(tokens))

      case remaining_tokens {
        [cell, ..rest] ->
          cell
          |> decode_token()
          |> result.map_error(fn(e) { CellError(cell, e) })
          |> result.map(constructor)
          |> result.map(fn(b) { #(b, rest) })

        [] -> Error(NotEnoughTokens)
      }
    },
    format: fn() {
      let #(constructor, tokens) = format()
      let _ = #(constructor(v), list.append(tokens, [encode_token(v)]))
      // I don't know if what I'm trying to do here is possible (on a mathematical logic level)
      // I will do other things and think about how I could do this in another way.
      todo
    },
  )
}
