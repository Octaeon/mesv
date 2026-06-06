//// A CSV parsing library that strongly enforces Data Integrity, allows for creation of both
//// a formatter (`fn(data) -> String`) and parser (`fn(String) -> data`) from the same
//// data type, and allows the user to add Frontmatter metadata to CSV files.
//// 
//// This root module is rather barren, as most of the relevant functionality is categorized
//// into the two modules, [`mesv/format`](mesv/format.html) and [`mesv/parse`](mesv/parse.html).
//// 
//// TODO : The goal of this branch is to implement a way to create a parser that does not consume
//// the cells of a CSV file in order every time, but instead first reads the headers, and based
//// on the headers' contents and their order, consumes the tokens in that specified order.
//// 
//// It's definitely doable, and also definitely doable in Gleam, I'm just not certain how it
//// should work with the other way of building parsers. I don't want to make them into different
//// data types, but I also don't know how I would even approach the problem of combining the
//// two methods.
//// 
//// Oh well, that's for the future when I actually get to it.
//// 

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
