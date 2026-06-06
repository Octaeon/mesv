//// A CSV parsing library that strongly enforces Data Integrity, allows for creation of both
//// a formatter (`fn(data) -> String`) and parser (`fn(String) -> data`) from the same
//// data type, and allows the user to add Frontmatter metadata to CSV files.
//// 
//// This root module is rather barren, as most of the relevant functionality is categorized
//// into the two modules, [`mesv/format`](mesv/format.html) and [`mesv/parse`](mesv/parse.html).
//// 
//// TODO : As of right now, only the [`parse`](mesv/parse.html) module has support for using
//// streams, and even that only partially (since inside both the preprocess function and run
//// function, these streams are consumed and eagerly evaluated to produce the output), only
//// as the input.
//// 
//// The goal of this branch is to add support for streams for every module, both as an input
//// and output.
//// 
//// Specifically:
//// - [`mesv/format`](mesv/format.html) needs support for `Stream`s as the input (so instead
////   of taking `List(a)`, allow for taking in `Stream(a)`), and the output (an API function
////   will output a `Stream(Row)` of strings, with or without row separators, I'm not sure -
////   anywho, there will be another function to easily fold this Stream into a single String).
//// - [`mesv/parse`](mesv/parse.html) should have an API function for converting a String into
////   a `Stream(Row)`, but also a function to do just that with a `filestream`, or, if it's
////   impossible without setting that library as a dependency, an API function that allows
////   for very easy and convenient creation of a `Stream` from a `filestream`. Additionally,
////   the output of the parser should also be available as a `Stream` - so, the ability to
////   easily turn a `Stream(Row)` into a `Stream(a)` using a `Parser(a, e)`.
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
