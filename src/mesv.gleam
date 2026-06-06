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
