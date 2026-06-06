//// Module containing the functions for creating a [`Parser`](parse.html#Parser), and
//// using it to parse an input CSV String into a `List` of some data types.
//// 
//// > **Important!** At this stage, everything is still in flux, and breaking changes can
////    occur on minor version updates. Be careful and check for possible issues before updating!
//// 
//// ## Examples
//// A full example of parsing an example CSV String.
//// ```gleam
//// import gleam/int
//// import mesv
//// import mesv/parse
//// 
//// const expected_data: List(#(String, Int, Bool)) = [
////   #("Andrew", 20, True),
////   #("Blake", 25, True),
////   #("Cassandra", 2, False),
//// ]
//// 
//// pub fn main() -> Nil {
////   let parsed_data =
////     parse.build({
////       // Create a parsing function using `mesv.parsed`
////       // to construct a curried parsing function
////       use name <- mesv.parsed
////       use age <- mesv.parsed
////       use adult <- mesv.parsed
//// 
////       // If any value fails (ie, returns Error(Nil)),
////       // the parsing of a row will stop.
////       // However, if it reaches here,
////       // it returns the following data type
////       #(name, age, adult)
////     })
////     |> parse.column(Ok)
////     |> parse.column(int.parse)
////     |> parse.column(fn(val: String) -> Result(Bool, Nil) {
////       case val {
////         "true" | "True" -> Ok(True)
////         "false" | "False" -> Ok(False)
////         _ -> Error(Nil)
////       }
////     })
////     // Specify that the first row is the headers,
////     // and if they don't match what is specified, 
////     // the parsing will fail
////     |> parse.expect_headers(["Name", "Age", "Is an adult"])
////     // Pass in the CSV String to parse
////     |> parse.run(
////       "Name,Age,Is an adult\n"
////       <> "Andrew,20,true\n"
////       <> "Blake,25,True\n"
////       <> "Cassandra,2,False",
////     )
//// 
////   assert parsed_data == Ok(list.map(expected_data, Ok))
//// }
//// ```
//// 
//// Parsing a CSV and performing some operations on the data immediately after parsing
//// ```gleam
//// // [...]
//// const expected_data: List(#(String, Int, Bool)) = [
////   #("Anna", 20, True),
////   #("Bob", 25, True),
////   #("Cleopatra", 2095, False),
////   // She's dead, she can't be an adult.
////   // But alas, our parser is too simple to understand
////   // this fact, so it will throw an error.
//// ]
//// 
//// pub fn main() -> Nil {
////   let parsed_data =
////     parse.build({
////       use name <- mesv.parsed
////       use age <- mesv.parsed
////       // As long as the operation is guaranteed to result
////       // in the data type specified in the Parser,
////       // you can do anything in here!
////       #(name, age, age >= 18)
////     })
////     |> parse.column(Ok)
////     |> parse.column(int.parse)
////     // Pass in the CSV String to parse
////     |> parse.run(
////       "Anna,20\n"
////       <> "Bob,25\n"
////       <> "Cleopatra,2095",
////     )
//// 
////   assert parsed_data == Ok(list.map(expected_data, Ok))
//// }
//// ```
//// 

import gleam/function
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import mesv/stream.{type Stream, Done, Next}
import mesv/util

/// Error type returned by the [`parse.preprocess`](parse.html#preprocess) function,
/// representing the outcomes that could've caused preprocessing the file to fail.
/// 
pub type PreprocessingError {
  /// Any one of the metadata fields couldn't be processed. The `rows` field inside this
  /// variant will never be empty, since if it were, this error would not be returned.
  /// 
  MetadataParsing(rows: List(MetadataRowError))
  /// The headers found in the first row of data after the metadata was finished did not
  /// match the expected headers passed to the Parser.
  /// 
  /// The first field of this variant, `found_headers` stores the cells of the first
  /// row that were found, in order.
  /// 
  /// The second field, `results`, stores the results of matching each of the successive
  /// headers to expected.
  /// 
  /// If the `ExpectedHeaders` type passed to the parser was `InOrderExact` or `InOrderMustPass`,
  /// then if a header matched or passed the check, then at its' index will be `Ok(i)` where
  /// `i` is its' index, so it can be ignored. However, if the `ExpectedHeaders` was
  /// `HeadersMustContain` or `HeadersMustContainPassing`, then an `Ok(i)` will be returned if
  /// a header matched or passed, and `i` will be the index of the check it passed or value
  /// it equaled.
  /// 
  HeadersMismatch(found_headers: List(String), results: List(Result(Int, Nil)))
  FailedHeaderParsing(reason: DataRowError(Nil))
  SourceEmpty
}

pub type MetadataRowError {
  NoSeparator(row: String)
  UnescapedSeparators(field: String)
  MetadataUnescapedEscapers(field: String)
  MetadataNonDuplicatedEscapers(field: String)
}

pub type DataRowError(a) {
  NotEnoughCells
  TooManyCells(leftovers: List(String))
  DataUnescapedEscapers(field: String)
  DataMismatchedEscapers(field: String)
  DataNonDuplicatedEscapers(field: String)
  CellParsingFailed(cell: String, reason: a)
}

/// The type describing how to create a value of type `a` from a String.
/// 
/// To create it, use the [`parse.build`](parse.html#build) function, the provided transformation
/// functions (`set_row_sep`, `set_col_sep`, `set_escaper`, `set_expected_headers`) to configure
/// the specific behaviour, and the [`parse.column`](parse.html#column) function to specify how
/// each subsequent column should be parsed.
/// 
/// Once you have the desired `Parser(a, e)`, use the [`parse.run`](parse.html#run) function to
/// convert a `String` into a `List(Result(a, ParsingError))`, and check out the
/// [`parse.get_parsed`](parse.html#get_parsed) function to easily extract the succesfully parsed
/// rows. 
/// 
pub opaque type Parser(a, b) {
  Parser(
    column_separator: String,
    row_separator: String,
    escaper: String,
    metadata_separator: String,
    expect_headers: ExpectedHeaders,
    parse: fn(List(String)) -> Result(#(a, List(String)), DataRowError(b)),
    strict_columns: Bool,
    trim_whitespace: #(Bool, Bool),
  )
}

pub type CsvSource {
  Text(String)
  RowStream(Stream(String))
}

/// A data type specifying what headers the `Parser` is to expect.
/// 
/// Not certain it is the final version yet.
/// 
pub type ExpectedHeaders {
  /// Ignore the contents of the first row, 
  Ignore
  // Doesn't matter what the first row is, just skip it
  Empty
  // Expect the file to start with the data 
  InOrderExact(List(String))
  // Expect the first row of headers to be **exactly** in this order, with **exactly** these elements
  HeadersMustContain(List(String))
  // Expect the first row of headers to have all of these elements, but in whatever order
  InOrderMustPass(List(fn(String) -> Bool))
  // Expect the first row of headers to return `True` when tested with the provided functions, in **exact** order.
  HeadersMustContainPassing(List(fn(String) -> Bool))
  // Expect each of the functions above to return `True` to at least one of the found headers.
}

/// This is a bad solution to what I'm doing. It will be changed (or made privete)
pub type HeaderAction {
  ParseFirstRow
  SkipFirstRow
}

/// Function for directly building a `Parser` that uses the subsequent elements in order.
/// 
/// The function passed in should be a curried one - ie, a function that returns a
/// function, and so on, with every subsequent function taking in some type of argument.
/// 
/// To build the parser, transform it using the [`parse.column`](parse.html#column)
/// function to specify how to parse each subsequent value in a row.
/// 
/// ## Examples
/// The simplest parser is one element:
/// ```gleam
/// parse.build(fn(str) { str })
///   |> parse.column(Ok)
/// ```
/// When used, it will create a `List(String)` containing the first cell of each
/// row of the input CSV String.
/// 
/// Infallible transformation of the data can be done both inside of the initial
/// function that is passed to `parse.build` and in `parse.column`, but fallible
/// transformations (those that output a `Result` or `Option` when the argument
/// requires what's inside the `Option`) must reside in the `parse.column` call.
/// 
/// A more complex `Parser` would be something like this:
/// ```gleam
/// parse.build({
///   use name: String <- mesv.parsed
///   use age: Int <- mesv.parsed
///   use adult: Bool <- mesv.parsed
///
///   #(name, age, adult)
/// })
/// ```
/// and to parse the arguments to construct the result, again, use the
/// [`parse.column`](parse.html#column) function.
/// 
pub fn build(f: fn(a) -> b) -> Parser(fn(a) -> b, e) {
  Parser(
    column_separator: ",",
    row_separator: "\n",
    metadata_separator: ":",
    escaper: "\"",
    expect_headers: Empty,
    parse: fn(tokens: List(String)) -> Result(
      #(fn(a) -> b, List(String)),
      DataRowError(e),
    ) {
      Ok(#(f, tokens))
    },
    strict_columns: False,
    trim_whitespace: #(True, True),
  )
}

// fn describe_error(err: ParsingError) -> String {
//   case err {
//     CantParseRow(index, contents, reason) ->
//       "Can't parse row #"
//       <> int.to_string(index)
//       <> " due to [ "
//       <> reason
//       <> " ]\n"
//       <> "contents: [ "
//       <> contents
//       <> " ]"
//     ExpectedHeadersMismatch(expected, found) ->
//       "Expected "
//       <> describe_expected_headers(expected)
//       <> ", found [ "
//       <> string.join(found, ", ")
//       <> " ]"
//     RanOutOfValues -> "Ran out of values"
//     StrictParsedWithLeftovers(leftovers) ->
//       "Encountered leftovers: [ " <> string.join(leftovers, ", ") <> " ]"
//     MalformedCell(element, description) ->
//       "Malformed cell: [ " <> element <> " ], because " <> description
//   }
// }
// fn describe_expected_headers(headers: ExpectedHeaders) -> String {
//   case headers {
//     Skip -> "Skip"
//     Empty -> "no headers"
//     InOrderExact(l) -> "Exactly [ " <> string.join(l, ", ") <> " ]"
//     HeadersMustContain(l) -> "Containing [ " <> string.join(l, ", ") <> " ]"
//     InOrderMustPass(_) -> "Ordered functions"
//     HeadersMustContainPassing(_) -> "Unordered functions"
//   }
// }

/// Transform a `Parser`, by passing in a parsing function for a specified column.
/// 
/// This function will be called for every row, and the output of this function,
/// if it's `Ok(a)`, will be passed to the `Parser`'s internal function,
/// and the parsing of the row continued;
/// 
/// If it's `Error(Nil)`, the parsing of the row will fail.
/// 
/// ## Examples
/// ```gleam
/// // Parser(fn(String) -> a)
/// parser
///   |> parse.column(Ok)
///   // Parser(a, e)
/// ```
/// 
pub fn column(
  parser: Parser(fn(a) -> b, e),
  parse: fn(String) -> Result(a, e),
) -> Parser(b, e) {
  Parser(..parser, parse: fn(tokens: List(String)) -> Result(
    #(b, List(String)),
    DataRowError(e),
  ) {
    use #(constructor, remaining_tokens) <- result.try(parser.parse(tokens))

    // This case ends up being run when the parser is running.
    // So, if the list ends up empty, that means that one row has too few elements
    // to build the expected data type.
    case remaining_tokens {
      [cell, ..rest] ->
        // TODO: Should I process the elements here, or no? I'm not sure
        cell
        |> parse()
        |> result.map_error(fn(e) { CellParsingFailed(cell, e) })
        |> result.map(constructor)
        |> result.map(fn(b) { #(b, rest) })

      [] -> Error(NotEnoughCells)
    }
  })
}

/// Documentation to be build :|
/// 
pub fn set_expected_headers(
  parser: Parser(a, e),
  headers: ExpectedHeaders,
) -> Parser(a, e) {
  Parser(..parser, expect_headers: headers)
}

/// Helper function for converting exact `ExpectedHeaders` into broader comparisons, by first
/// applying the `transform` function to both the found and expected values before checking
/// if they are identical.
/// 
/// **Note**: Due to limitations in the underlying representation of the expected headers,
/// only the `InOrderExact` and `HeadersMustContain` values will be transformed. If you wish
/// to chain multiple transformations, call this function only once with a function that
/// itself composes multiple transformations.
/// 
/// Of course, values like `Skip` and `Empty` will not be transformed.
/// 
/// Use this function if you expect headers in the first row and want more granular control
/// over what the acceptable values are, but don't want to manually write a verification
/// function for each header.
/// 
/// ## Examples
/// ```gleam
/// parser
///   |> parse.set_expected_headers(InOrderExact(["Name", "Age"]))
///   |> parse.run("name,age\n...")
///   // -> Error(ExpectedHeadersMismatch)
///   //    found ["name", "age"]
/// ```
/// By using this function, you can avoid such annoyances
/// ```gleam
/// parser
///   |> parse.set_expected_headers(
///     InOrderExact(["Name", "Age"])
///       |> parse.transform_headers(string.lowercase)
///   )
///   |> parse.run("name,age\n...")
///   // -> Ok(...)
/// ```
/// 
pub fn transform_headers(
  headers: ExpectedHeaders,
  transform fun: fn(String) -> String,
) -> ExpectedHeaders {
  case headers {
    Ignore -> Ignore
    Empty -> Empty
    InOrderExact(headers) ->
      InOrderMustPass(
        list.map(headers, fn(expected_col: String) -> fn(String) -> Bool {
          fn(found_col: String) -> Bool { fun(expected_col) == fun(found_col) }
        }),
      )
    HeadersMustContain(headers) ->
      HeadersMustContainPassing(
        list.map(headers, fn(expected_col: String) -> fn(String) -> Bool {
          fn(found_col: String) -> Bool { fun(expected_col) == fun(found_col) }
        }),
      )
    // I'm not happy that I can't transform the other two.
    // Maybe this is not the best solution?
    _ -> headers
  }
}

/// > **This function is deprecated, and should be replaced with the
///   [`parse.set_expected_headers`](parse.html#set_expected_headers) function.**
/// 
/// Configure the parser to treat the first parsed row as the headers,
/// and specify that we expect the CSV headers to equal these headers.
/// 
/// If the first row is not **strictly identical** to the contents of
/// the arguments to this function, the parser will return an `Error`.
/// 
/// ## Note
/// To replace this function with the [`set_expected_headers`](parse.html#set_expected_headers)
/// while preserving behaviour, call it like so:
/// ```gleam
/// // change from
/// |> parse.expect_headers(["some", "headers"])
/// // to
/// |> parse.set_expected_headers(InOrderExact(["some", "headers"]))
/// ```
/// For more information, see the documentation of the function in question.
/// 
@deprecated("
A new function, set_expected_headers was created, with extended functionality and more documentation.
For new code, use that one.
")
pub fn expect_headers(
  parser: Parser(a, e),
  headers: List(String),
) -> Parser(a, e) {
  Parser(..parser, expect_headers: InOrderExact(headers))
}

/// Function to set a specific row separator, instead of the default newline (`\n`)
/// 
/// ## Examples
/// ```gleam
/// parser
///   |> parse.parse("a,1,c\nd,4,a")
///   // -> parse returns [#("a", 1, "c"), #("d", 4, "a")]
/// 
/// parser
///   |> set_row_sep("|")
///   |> parse.parse("a,1,c\nd,4,a")
///   // -> parse returns [#("a", 1, "c\nd")]
///   // the two cells "4" and "a" are treated as leftovers
/// parser
///   |> set_row_sep("|")
///   |> parse.parse("a,1,c|d,4,a")
///   // -> parse returns [#("a", 1, "c"), #("d", 4, "a")]
/// ```
/// 
pub fn set_row_sep(
  parser: Parser(a, e),
  new_row_separator: String,
) -> Parser(a, e) {
  Parser(..parser, row_separator: new_row_separator)
}

/// Function to set a specific key-value metadata separator, instead of the default colon (`:`)
/// 
pub fn set_meta_sep(
  parser: Parser(a, e),
  new_metadata_separator: String,
) -> Parser(a, e) {
  Parser(..parser, metadata_separator: new_metadata_separator)
}

/// Function to set a specific value escaper, instead of the default doublequotes (`"`)
/// 
/// Escapers are wrapped around a cell if that cell contains any one or more of:
/// - column separator (by default `,`)
/// - row separator (by default `\n`)
/// - escaper itself
/// 
/// In the event that a cell contains an escaper, the escaper is first replaced
/// with two escapers.
/// 
/// So `here's " ` would first become `here's "" `, then be wrapped and become
/// `"here's "" "`.
/// 
/// ## Examples
/// ```gleam
/// parser
///   |> parse.parse("a,'b','c'''")
///   // -> row returns Ok(#("a", "'b'", "'c'''"))
/// parser
///   |> parse.parse("a,\"b\",\"c\"\"\"")
///   // -> row returns Ok(#("a", "b", "c\""))
/// 
/// parser
///   |> set_escaper("'")
///   |> parse.parse("a,'b','c'''")
///   // -> row returns Ok(#("a", "b", "c'"))
/// parser
///   |> set_escaper("'")
///   |> parse.parse("a,\"b\",\"c\"\"\"")
///   // -> row returns Ok(#("a", "\"b\"", "\"c\"\"\""))
/// ```
/// 
pub fn set_escaper(parser: Parser(a, e), new_escaper: String) -> Parser(a, e) {
  Parser(..parser, escaper: new_escaper)
}

/// Function to set whether the parser should trim the whitespace on both ends of each value.
/// This operation is performed **before** the contents of the cell are parsed using the
/// functions from [`parse.column`](parse.html#column).
/// 
/// This operation is performed after the cell is unwrapped (escapers removed), so if
/// the CSV file was modified somehow (for example, using VSCode plugin [Rainbow
/// CSV](https://marketplace.visualstudio.com/items?itemName=mechatroner.rainbow-csv)
/// to align the columns), the cells that were escaped will have their whitespace match
/// the contents from before the CSV file was modified, while the cells that were not
/// escaped will be parsed after this function.
/// 
/// So, if you use this function to disable whitespace trimming, it will mostly affect
/// unescaped cells.
/// 
/// ## Examples
/// By default, the parser will trim both the start and end of each cell:
/// ```gleam
/// parser
///   |> parse.run("a   , 1,\"c\n  \"")
///   // -> Ok(#("a", 1, "c"))
/// ```
/// If you disable trimming whitespace, parsing cells with whitespace that are not inside
/// the escapers will still work, but the whitespace not inside the escapers will be
/// trimmed regardless:
/// ```gleam
/// parser
///   |> parse.set_trim_whitespace(False, False)
///   |> parse.run("a   ,1,\"c\n  \"")
///   // -> Ok(#("a   ", 1, "c\n  "))
///   // [...]
///   |> parse.run("a   ,    \"1\"   ,\"c\n  \"     ")
///   // -> Ok(#("a   ", 1, "c\n  "))
///   // For the last element, the whitespace around the escapers was trimmed
/// ```
/// Additionally, this function takes in two labelled arguments, making it possible to
/// only trim one end of a cell.
/// ```gleam
/// parser
///   |> parse.set_trim_whitespace(start: True, end: False)
///   |> parse.run("Author's name,    Book title aligned somehow    ,   1999")
///   // -> Ok(#("Author's name", "Book title aligned somehow    ", 1999))
/// ```
/// 
/// Lastly, if you want to preserve whitespace for most of the cells (such as for
/// `String`s), but some require being trimmed, simply modify the parsing function
/// you pass to the [`parse.column`](parse.html#column) function.
/// ```gleam
/// // [...]
///   |> parse.column(Ok) // Accept the string as is
///   |> parse.column(Ok) // Same as above
///   |> parse.column(fn(num: String) {
///     num |> string.trim |> int.parse 
///   })
///   |> parse.set_trim_whitespace(False, False)
///   |> parse.run(
///     "Author's name,    Book title aligned somehow    , \"  1999\n  \""
///   )
///   // -> Ok(#(
///   //    "Author's name", "Book title aligned somehow    ", 1999
///   //    ))
/// ```
/// 
pub fn set_trim_whitespace(
  parser: Parser(a, e),
  start trim_start: Bool,
  end trim_end: Bool,
) -> Parser(a, e) {
  Parser(..parser, trim_whitespace: #(trim_start, trim_end))
}

/// Function to set a specific column separator, instead of the default comma (`,`)
/// 
/// ## Examples
/// ```gleam
/// parser
///   |> parse.parse("a,1,c")
///   // -> row returns Ok(#("a", 1, "c"))
/// 
/// parser
///   |> set_col_sep("|")
///   |> parse.parse("a,1,c")
///   // -> row returns Error(RanOutOfValues)
/// parser
///   |> set_col_sep("|")
///   |> parse.parse("a|1|c")
///   // -> row returns Ok(#("a", 1, "c"))
/// ```
/// 
pub fn set_col_sep(
  parser: Parser(a, e),
  new_column_separator: String,
) -> Parser(a, e) {
  Parser(..parser, column_separator: new_column_separator)
}

/// Function to make the parser expect strictly the required number of columns for each row.
/// 
/// This means that when parsing a row, there must be exactly as many cells as there were
/// arguments for the internal `Parser` function. If this function is called, if there are
/// any leftover values after the parsing is finished, parsing that row returns an `Error`
/// even if the parsing returned a value.
/// 
/// ## Examples
/// ```gleam
/// parser
///   |> parse.parse("a,1,c")
///   // -> row returns Ok(#("a", 1))
/// 
/// parser
///   |> set_strict_columns()
///   |> parse.parse("a,1,c")
///   // -> row returns Error(StrictParsedWithLeftovers(["c"]))
/// ```
/// 
pub fn set_strict_columns(parser: Parser(a, e)) -> Parser(a, e) {
  Parser(..parser, strict_columns: True)
}

/// Internal helper function to check whether the CSV headers that were found match
/// the expected pattern that was specified in the Parser building process.
/// 
fn make_header_processor(
  parser: Parser(a, e),
) -> fn(ExpectedHeaders, List(String)) ->
  Result(HeaderAction, PreprocessingError) {
  let unescape = fn(cell) {
    make_unescaper(parser)(cell)
    |> result.map_error(fn(err) {
      FailedHeaderParsing(case err {
        CellParsingFailed(cell, _) -> CellParsingFailed(cell, Nil)
        NotEnoughCells -> NotEnoughCells
        TooManyCells(leftovers) -> TooManyCells(leftovers)
        DataUnescapedEscapers(field) -> DataUnescapedEscapers(field)
        DataMismatchedEscapers(field) -> DataMismatchedEscapers(field)
        DataNonDuplicatedEscapers(field) -> DataNonDuplicatedEscapers(field)
      })
    })
  }

  fn(expected: ExpectedHeaders, found: List(String)) -> Result(
    HeaderAction,
    PreprocessingError,
  ) {
    // First unescape all headers. If the header row has an incorrect format, even if the
    // user selected to skip it, the parsing will return an error.
    use processed_headers <- result.try(result.all(found |> list.map(unescape)))

    // Based on the length of the requirements and the found headers,
    // decide whether to proceed or return a PreprocessingError.
    let length_guard = fn(req: List(f)) -> Result(List(f), PreprocessingError) {
      let requirements = list.length(req)
      let headers = list.length(processed_headers)
      case requirements <= headers, headers <= requirements {
        False, _ -> Error(FailedHeaderParsing(NotEnoughCells))
        True, True -> Ok(req)
        True, False if parser.strict_columns -> {
          Error(FailedHeaderParsing(TooManyCells(processed_headers)))
        }
        True, False -> Ok(req)
      }
    }

    case expected {
      Ignore -> Ok(SkipFirstRow)
      Empty -> Ok(ParseFirstRow)
      InOrderExact(ordered_exact) ->
        ordered_exact
        |> length_guard()
        |> result.try(fn(required_headers: List(String)) {
          let matching =
            list.map2(
              required_headers,
              processed_headers,
              fn(expected_col: String, found_col: String) -> Bool {
                expected_col == found_col
              },
            )

          case list.all(matching, function.identity) {
            True -> Ok(SkipFirstRow)
            False ->
              Error(HeadersMismatch(
                processed_headers,
                matching
                  |> list.index_map(fn(passed, index) {
                    case passed {
                      True -> Ok(index)
                      False -> Error(Nil)
                    }
                  }),
              ))
          }
        })

      HeadersMustContain(unordered_exact) ->
        unordered_exact
        |> length_guard()
        |> result.try(fn(requirements: List(String)) {
          // TODO : As of right now, this implementation only checks whether each header passes
          // one requirement, not that each requirement has its' own unique header that passed it.
          // What this means is, if a requirement that happens to be earlier has two headers that
          // match, and takes the first, and a requirement later on only has one header that was already
          // taken, it would cause an error, even though it should've been fine.

          // This is not relevant at all yet, and there aren't any tests for this, but it is something
          // I felt the need to note.
          let headers_matching_map =
            requirements
            |> list.map(fn(req) {
              // For each requirement, check all headers to see if they match
              list.map(processed_headers, fn(el) { el == req })
            })
            // turn the list of requirements' headers that pass to a list of
            // headers' requirements that they pass
            |> list.transpose()
            // For each of the found headers, get the index of the first requirement it satisfies,
            // or if it doesn't satisfy any, `Error(Nil)`.
            |> list.map(fn(header_passing_reqs) {
              header_passing_reqs
              |> list.index_map(fn(passed_req, index) { #(index, passed_req) })
              |> list.find_map(fn(first_passing_req) {
                case first_passing_req.1 {
                  True -> Ok(first_passing_req.0)
                  False -> Error(Nil)
                }
              })
            })

          case result.all(headers_matching_map) {
            Ok(_) -> Ok(SkipFirstRow)
            Error(_) ->
              Error(HeadersMismatch(processed_headers, headers_matching_map))
          }
        })

      InOrderMustPass(ordered_custom) ->
        ordered_custom
        |> length_guard()
        |> result.try(fn(required_headers: List(fn(String) -> Bool)) {
          let matching =
            list.map2(
              required_headers,
              processed_headers,
              fn(must_pass: fn(String) -> Bool, found_col: String) -> Bool {
                must_pass(found_col)
              },
            )

          case list.all(matching, function.identity) {
            True -> Ok(SkipFirstRow)
            False ->
              Error(HeadersMismatch(
                processed_headers,
                matching
                  |> list.index_map(fn(passed, index) {
                    case passed {
                      True -> Ok(index)
                      False -> Error(Nil)
                    }
                  }),
              ))
          }
        })

      HeadersMustContainPassing(unordered_custom) ->
        unordered_custom
        |> length_guard()
        |> result.try(fn(requirements: List(fn(String) -> Bool)) {
          // TODO : As of right now, this implementation only checks whether each header passes
          // one requirement, not that each requirement has its' own unique header that passed it.
          // What this means is, if a requirement that happens to be earlier has two headers that
          // match, and takes the first, and a requirement later on only has one header that was already
          // taken, it would cause an error, even though it should've been fine.

          // This is not relevant at all yet, and there aren't any tests for this, but it is something
          // I felt the need to note.
          let headers_matching_map =
            requirements
            |> list.map(fn(req) {
              // For each requirement, check all headers to see if they satisfy the requirement
              list.map(processed_headers, fn(el) { req(el) })
            })
            // turn the list of requirements' headers that pass to a list of
            // headers' requirements that they pass
            |> list.transpose()
            // For each of the found headers, get the index of the first requirement it satisfies,
            // or if it doesn't satisfy any, `Error(Nil)`.
            |> list.map(fn(header_passing_reqs) {
              header_passing_reqs
              |> list.index_map(fn(passed_req, index) { #(index, passed_req) })
              |> list.find_map(fn(first_passing_req) {
                case first_passing_req.1 {
                  True -> Ok(first_passing_req.0)
                  False -> Error(Nil)
                }
              })
            })

          case result.all(headers_matching_map) {
            Ok(_) -> Ok(SkipFirstRow)
            Error(_) ->
              Error(HeadersMismatch(processed_headers, headers_matching_map))
          }
        })
    }
  }
}

fn take_until_unescaped(
  separator el: String,
  not_in escaper: String,
) -> fn(String) -> Result(#(String, String), String) {
  fn(source: String) -> Result(#(String, String), String) {
    take_until_unescaped_loop(source, el, escaper, "")
    |> result.map(pair.swap)
    |> result.map_error(fn(_) { source })
  }
}

fn take_until_unescaped_loop(
  from: String,
  separator: String,
  esc: String,
  acc: String,
) -> Result(#(String, String), Nil) {
  case string.split_once(from, separator) {
    Ok(#(head, rest)) -> {
      let value = acc <> head
      case util.count_non_overlapping(in: value, of: esc) % 2 == 0 {
        True -> Ok(#(value, rest))
        False ->
          take_until_unescaped_loop(
            rest,
            separator,
            esc,
            // Almost made the same mistake again, lmao
            acc <> separator <> head,
          )
      }
    }
    Error(Nil) -> Error(Nil)
  }
}

fn make_row_stream(parser: Parser(a, e)) -> fn(String) -> Stream(String) {
  fn(source: String) -> Stream(String) {
    stream.from_divider(
      source,
      take_until_unescaped(parser.row_separator, parser.escaper),
    )
  }
}

/// Internal function for creating a row splitting function directly from a `Parser`.
/// 
fn make_row_splitter(parser: Parser(a, e)) -> fn(CsvSource) -> List(String) {
  fn(source: CsvSource) -> List(String) {
    case source {
      Text(str) ->
        str
        |> util.split_on_unescaped(
          separator: parser.row_separator,
          not_in: parser.escaper,
        )
      RowStream(stream) -> stream |> stream.to_list()
    }
  }
}

/// Internal function for creating a column splitting function directly from a `Parser`.
/// 
fn make_column_splitter(parser: Parser(a, e)) -> fn(String) -> List(String) {
  util.split_on_unescaped(
    separator: parser.column_separator,
    not_in: parser.escaper,
  )
}

/// Internal function for creating a trimming function directly from a `Parser`.
/// 
fn make_content_trimmer(parser: Parser(a, e)) -> fn(String) -> String {
  let #(trim_start, trim_end) = parser.trim_whitespace
  fn(element: String) -> String {
    element
    |> case trim_start {
      True -> string.trim_start
      False -> function.identity
    }
    |> case trim_end {
      True -> string.trim_end
      False -> function.identity
    }
  }
}

/// Internal function for creating an unescaping function directly from a `Parser`.
/// 
fn make_unescaper(
  parser: Parser(a, e),
) -> fn(String) -> Result(String, DataRowError(e)) {
  let escaper = parser.escaper
  // Unescape the String - for now, just deduplicate the escaper characters
  // (According to the CSV format standard, if any doubleQuotes appear inside a cell,
  // they must be replaced with two of them, and the entire cell wrapped)
  let deduplicate = fn(cell: String) -> String {
    cell
    |> string.remove_prefix(escaper)
    |> string.remove_suffix(escaper)
    |> util.multi_replace([#(escaper <> escaper, escaper)])
  }

  let starts = fn(cell: String) -> Bool { string.starts_with(cell, escaper) }
  let ends = fn(cell: String) -> Bool { string.ends_with(cell, escaper) }
  let count = fn(cell: String) -> #(Int, Int) {
    let unwrapped =
      cell
      |> string.remove_prefix(escaper)
      |> string.remove_suffix(escaper)
    #(
      util.count_non_overlapping(in: unwrapped, of: escaper),
      // Count single escapers
      util.count_non_overlapping(in: unwrapped, of: escaper <> escaper),
      // Count duplicated
    )
  }

  // This might be overkill. Maybe instead of insisting on doing things with functional patterns
  // I should bite the bullet and do things like this by just consuming the String one character
  // at a time with a state machine implemented with recursive functions.
  fn(cell: String) -> Result(String, DataRowError(e)) {
    // First trim the whitespace from the cell, so if the CSV String was modified (such as aligning the columns)
    // it will not affect this program from correctly unescaping cells.
    let trimmed = string.trim(cell)
    // Count the number of escapers in the cell
    let #(num_single, num_duplicated) = count(trimmed)

    // Check if the number of escapers in the cell is even
    case num_single, starts(trimmed), ends(trimmed) {
      n, True, True if n % 2 == 0 && n == num_duplicated * 2 ->
        // If it was even and wrapped in escapers, remove them along with the whitespace wrapping the cell
        Ok(deduplicate(trimmed))
      n, False, False if n == 0 && num_duplicated == 0 -> Ok(cell)
      _, a, b if a != b -> Error(DataMismatchedEscapers(trimmed))
      n, False, False if n != 0 -> Error(DataUnescapedEscapers(trimmed))
      n, _, _ if n % 2 != 0 -> Error(DataMismatchedEscapers(trimmed))
      n, _, _ if n != num_duplicated * 2 ->
        // If the cell starts with an escaper but does not end in one, then something went wrong,
        // and we are returning an error.
        Error(DataNonDuplicatedEscapers(trimmed))
      _, _, _ ->
        // If the cell starts with an escaper but does not end in one, then something went wrong,
        // and we are returning an error.
        Error(DataMismatchedEscapers(trimmed))
    }
  }
}

/// Internal function for creating a finalizer function that takes in the parsed
/// value along with the leftover tokens, and returns a `Result(a, ParsingError)`.
/// 
fn make_finalizer(
  parser: Parser(a, e),
) -> fn(#(a, List(String))) -> Result(a, DataRowError(e)) {
  case parser.strict_columns {
    True -> fn(output: #(a, List(String))) -> Result(a, DataRowError(e)) {
      let #(value, leftovers) = output
      case leftovers {
        // Strict columns and no leftovers, proceed
        [] -> Ok(value)
        // Strict columns and found leftovers, Error
        _ -> Error(TooManyCells(leftovers))
      }
    }
    False -> fn(output: #(a, List(String))) -> Result(a, DataRowError(e)) {
      // Just ignore the leftovers
      Ok(output.0)
    }
  }
}

/// Preprocess the `source` of the CSV file by reading all of the metadata contained in the
/// frontmatter block (started and ended by a row containing only three `-` characters, like
/// so: `---` ) as well as the headers as specified in the `expect_headers` function.
/// 
/// ### Return explanation
/// Returns a `Result`:
/// - `Error(String)` if the headers didn't match
/// - `Ok(#(List(#(String, String)), Parser(a, e), String))` if the headers did match.
/// 
/// In the case of an `Ok`, the values are like so:
/// - The first `List(#(String, String))` is the list of metadata at the beginning. Right now,
///   if the user wants to do something with it, they must do so manually.
/// - Second element `Parser(a, e)` - a modified parser to use when calling the
///   [`parse.run`](parse.html#run) function later - it will expect that the first row
///   is the first data point, and will behave accordingly.
/// - The third element `String` is the contents of the CSV file with the metadata and header
///   row removed, which is what should go into the [`parse.run`](parse.html#run) function later.
///   If you for some reason want to use `mesv` only for processing metadata, you could discard
///   everything else and parse this `String` with another library.
/// 
/// As of right now, the frontmatter metadata can only be parsed if it follows the grammar
/// `key sep value newline`, where `sep` is by default `:` and `newline` is the same as the
/// CSV newline.
/// 
/// Read more about this on the [MESV grammar](mesv-grammar.html) page.
/// 
pub fn preprocess(
  parser: Parser(a, e),
  source: CsvSource,
) -> Result(
  #(List(#(String, String)), Parser(a, e), CsvSource),
  PreprocessingError,
) {
  let #(row_stream, metadata) =
    case source {
      Text(str) -> make_row_stream(parser)(str)
      RowStream(stream) -> stream
    }
    |> read_metadata(make_metadata_parser(parser))

  let process_headers = make_header_processor(parser)

  case stream.next(row_stream) {
    Next(stream, value) -> {
      use row_stream <- result.try(
        case
          process_headers(
            parser.expect_headers,
            make_column_splitter(parser)(value),
          )
        {
          Ok(SkipFirstRow) -> Ok(stream)
          Ok(ParseFirstRow) -> Ok(stream.prepend(stream, value))
          Error(err) -> Error(err)
        },
      )
      let parser = parser |> set_expected_headers(Empty)
      let data = row_stream |> RowStream
      Ok(#(metadata, parser, data))
    }
    Done -> Error(SourceEmpty)
  }
}

fn read_metadata(
  rows: Stream(String),
  parse_metadata_row: fn(String) -> Result(#(String, String), Nil),
) -> #(Stream(String), List(#(String, String))) {
  case stream.next(rows) {
    Next(stream, "---") -> {
      stream
      |> stream.collect_until(fn(row: String) -> Bool { row == "---" })
      |> pair.map_second(list.filter_map(_, parse_metadata_row))
      |> pair.map_first(stream.drop(_, 1))
    }
    Next(stream, row) -> #(stream.prepend(stream, row), [])
    Done -> #(stream.empty(), [])
  }
}

fn make_metadata_parser(
  parser: Parser(a, e),
) -> fn(String) -> Result(#(String, String), Nil) {
  let unescape = make_unescaper(parser)
  fn(row: String) -> Result(#(String, String), Nil) {
    case take_until_unescaped_loop(row, ":", parser.escaper, "") {
      Ok(#(key, value)) -> {
        case unescape(key), unescape(value) {
          Ok(unescaped_key), Ok(unescaped_value) ->
            Ok(#(unescaped_key, unescaped_value))
          _, _ -> Error(Nil)
        }
      }
      Error(Nil) -> Error(Nil)
    }
  }
}

/// Function to use the specified `Parser(a, e)` to transform the `source` into a
/// `Result(List(Result(a, ParsingError)))`.
/// 
/// If the headers specified in the [`parse.set_expected_headers`](parse.html#set_expected_headers)
/// function did not match the first row contents, a `ParsingError` will be returned, of the type
/// `ExpectedHeadersMismatch`, containing both the expected headers and what was found.
/// 
/// If the headers weren't specified, or were specified and match the expected pattern,
/// the function will return `Ok(List(Result(a, ParsingError)))`.
/// 
/// If you need a simple way to get the `List(a)` out of that, use the
/// [`parse.get_parsed`](parse.html#get_parsed) function.
/// 
/// The first is the list of all rows that were successfully parsed, while the second is a
/// list of `ParsingError`s that were thrown due to a row failing to parse.
/// 
/// > What to do with both of these Lists is up to the user, whether to ignore all errors or abort
///   if any errors occur.
/// 
/// ## Order of operations
/// The order of operations when parsing is as such:
/// 1. The rows of the source `String` are split using the
///    [`util.split_on_unescaped`](util.html#split_on_unescaped) helper function.
/// 2. If the `List(String)` of the rows is not empty, first check if the headers match what
///    the user specified.
/// 3. If they do, process each row in turn:
///    - Split row `String` into a `List(String)` of raw cells
///    - Unwrap each cell by first trimming whitespace surrounding it. If the trimmed `String`
///      both starts and ends with the escaper, remove them and return what was wrapped in them;
///      if not, return the original raw cell. If the trimmed string only has the escaper on
///      *one* end, return an `Error(MalformedCell)`.
///    - If all of the cells returned an `Ok`, proceed
///    - Unescape each cell's contents by deduplicating the escaper characters
///    - Trim the whitespace of each cell according to what the user specified using the
///      [`parse.set_trim_whitespace`](parse.html#set_trim_whitespace) function
///    - Parse the row by passing in the contents of the cells to the parsing functions from
///      [`parse.column`](parse.html#column), then if they return `Ok`, passing in the output
///      to the curried constructor function passed into the [`parse.build`](parse.html#build)
///      function
/// 4. Return a `List(Result(a, ParsingError))` and wrap it in `Ok`
/// 
pub fn run(
  parser: Parser(a, e),
  source: CsvSource,
) -> List(Result(a, DataRowError(e))) {
  case make_row_splitter(parser)(source) {
    // Empty file - just return an empty list.
    [] -> []
    [headers, ..contents] -> {
      // A locally defined function capturing the parser data, that is used for processing each row
      let process_row = fn(cells: List(String)) -> Result(a, DataRowError(e)) {
        cells
        // Unescape the String - ie, if the escape characters are present both at the beginning
        // and end of the String, remove them, and deduplicate any internal escapers.
        // If only one end of the String has an escaper, throw a Parsing error for this row.
        |> list.map(make_unescaper(parser))
        // Only proceed if all cells in this row are unwrapped
        |> result.all()
        |> result.try(fn(elements: List(String)) -> Result(a, DataRowError(e)) {
          elements
          // Trim white space according to the rules set.
          // By this point, the string is unwrapped and unescaped, so what to do with it
          // is up to the user.
          |> list.map(make_content_trimmer(parser))
          // Call the Parsing function to convert the `List(String)` of elements
          // (already unescaped, unwrapped and trimmed) to try and convert it into
          // the desired data type `a`.
          |> parser.parse()
          // If the parsing step succeeded, check whether there were any leftovers,
          // and depending on the parser settings, either proceed or throw an error.
          |> result.try(make_finalizer(parser))
        })
      }

      let contents = case parser.expect_headers {
        Ignore -> contents
        _ -> [headers, ..contents]
      }

      contents
      |> list.map(fn(row_string) {
        // All of the parsing functions are condensed here to avoid having to map multiple times.
        row_string
        |> make_column_splitter(parser)
        |> process_row()
      })
    }
  }
}

/// > **This function is deprecated, and should be replaced with the
///   [`parse.run`](parse.html#run) function.**
/// 
/// Function to use the specified `Parser(a, e)` to transform the source into a `#(List(a),
/// List(ParsingError))`.
/// 
/// To follow the expected previous behaviour, it returns a `Result(#(List(a),
/// List(ParsingError)), ParsingError)`, obtained by calling `result.partition` on
/// the list of `Result(a, ParsingError)` from parsing rows.
/// 
@deprecated("
To simplify the API and comply with the Gleam convention, I have decided to rename the parse
function to `run`. This function is still available to call, but should be replaced if possible.
In new code, use the `run` function.
")
pub fn parse(
  parser: Parser(a, e),
  source: String,
) -> Result(#(List(a), List(DataRowError(e))), PreprocessingError) {
  preprocess(parser, Text(source))
  |> result.map(fn(preprocess_out) {
    // Using this function means ignoring the parsed metadata
    let #(_metadata, parser, csv_source) = preprocess_out
    run(parser, csv_source)
    |> result.partition
    |> pair.map_first(list.reverse)
    |> pair.map_second(list.reverse)
  })
}

/// Helper function to easily extract the successfully parsed rows from the output of
/// the [`parse.run`](parse.html#run) function.
/// 
/// ## Examples
/// Without using this function:
/// ```gleam
/// parse.run(parser, "1,2\n1,\ntext,1.2")
/// // -> [ Ok(#(1, 2))
/// //    , Error(RanOutOfValues)
/// //    , Error(CantParseRow)
/// //    ]
/// ```
/// With the function:
/// ```gleam
/// parse.run(parser, "1,2\n1,\ntext,1.2")
///   |> parse.get_parsed()
///   // -> [ #(1, 2) ]
/// ```
/// 
/// Of course, this is all under the assumption that the parsing succeeded initially
/// and started execution.
/// 
pub fn get_parsed(rows: List(Result(a, DataRowError(e)))) -> List(a) {
  rows |> list.filter_map(function.identity)
}

pub fn then(
  preprocessed: Result(
    #(List(#(String, String)), Parser(a, e), CsvSource),
    PreprocessingError,
  ),
) -> Result(
  #(List(#(String, String)), List(Result(a, DataRowError(e)))),
  PreprocessingError,
) {
  preprocessed
  |> result.map(fn(a) {
    let #(metadata, parser, csv_source) = a
    #(metadata, run(parser, csv_source))
  })
}

pub fn just_data(
  processed: Result(
    #(List(#(String, String)), List(Result(a, DataRowError(e)))),
    PreprocessingError,
  ),
) -> Result(List(Result(a, DataRowError(e))), PreprocessingError) {
  result.map(processed, pair.second)
}
