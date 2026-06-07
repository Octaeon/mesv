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

pub type Mapping(a, e) {
  Mapping(encode: fn(a) -> String, decode: fn(String) -> Result(a, e))
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
    parse: fn(List(String)) -> #(List(String), Result(a, e)),
    format: fn(fn(a) -> String) -> fn(a) -> List(String),
  )
}

pub fn build(constructor: fn(a) -> b) -> Builder(fn(a) -> b, CellError(e)) {
  Builder(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    metadata_separator: ":",
    parse: fn(tokens: List(String)) -> #(
      List(String),
      Result(fn(a) -> b, CellError(e)),
    ) {
      let _out = case tokens {
        [] -> #([], Error(NotEnoughTokens))
        [first, ..rest] -> #(rest, Ok(fn(mapping: a) -> b { todo }))
      }
    },
    format: fn(encoder: fn(fn(a) -> b) -> String) -> fn(fn(a) -> b) ->
      List(String) {
      fn(transform: fn(a) -> b) -> List(String) { [encoder(transform)] }
    },
  )
}

pub fn column(
  builder: Builder(fn(a) -> b, CellError(e)),
  mapping: Mapping(a, e),
) -> Builder(b, CellError(e)) {
  let Mapping(encode_token, decode_token) = mapping
  let Builder(
    column_separator,
    row_separator,
    escaper,
    metadata_separator,
    parse,
    format,
  ) = builder

  let tes = fn(transform: fn(a) -> b) -> String {
    let _ = fn(l: a) { transform(l) }
    todo
  }
  Builder(
    column_separator,
    row_separator,
    escaper,
    metadata_separator,
    fn(tokens: List(String)) -> #(List(String), Result(b, CellError(e))) {
      let #(remaining_tokens, result) = parse(tokens)
      case result {
        Ok(constructor) -> {
          case remaining_tokens {
            [] -> #([], Error(NotEnoughTokens))
            [first, ..rest] -> #(
              rest,
              decode_token(first)
                |> result.map(constructor)
                |> result.map_error(fn(err) {
                  CellError(cell: first, error: err)
                }),
            )
          }
        }
        Error(e) -> #(remaining_tokens, Error(e))
      }
    },
    fn(value: fn(b) -> String) -> fn(b) -> List(String) {
      fn(encode: b) -> List(String) {
        // let t = encode(value)
        todo
      }
    },
  )
}
