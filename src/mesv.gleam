//// A CSV parsing library that strongly enforces Data Integrity, allows for creation of both
//// a formatter (`fn(data) -> String`) and parser (`fn(String) -> data`) from the same
//// data type, and allows the user to add Frontmatter metadata to CSV files.
//// 
//// This root module is rather barren, as most of the relevant functionality is categorized
//// into the two modules, `mesv.format` and `mesv.parse`.

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
