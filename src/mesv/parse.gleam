//// Module containing the functions for creating a [[parse.html#Parser|`Parser`]], and
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
import mesv/util

/// An error type representing any kind of error encountered when parsing.
/// 
/// In the future, a better `Error` type and error handling will be implemented,
/// but it should do its' job for now.
/// 
pub type ParsingError {
  CantParseRow(index: Int, contents: String, reason: String)
  ExpectedHeadersMismatch(expected: ExpectedHeaders, found: List(String))
  RanOutOfValues
  StrictParsedWithLeftovers(leftovers: List(String))
  MalformedCell(element: String, description: String)
}

/// The type describing how to create a value of type `a` from a String.
/// 
/// To create it, use the [[parse.html#build|`parse.build`]] function, the provided transformation
/// functions (`set_row_sep`, `set_col_sep`, `set_escaper`, `expect_headers`) to configure the
/// specific behaviour, and the [[parse.html#column|`parse.column`]] function to specify how each
/// subsequent column should be parsed.
/// 
/// Once you have the desired `Parser(a)`, use the [[parse.html#run|`parse.run`]] function to
/// convert a `String` into a `List(Result(a, ParsingError))`, and check out the
/// `parse.get_parsed` function to easily extract the succesfully parsed rows. 
/// 
pub opaque type Parser(a) {
  Parser(
    column_separator: String,
    row_separator: String,
    escaper: String,
    expect_headers: ExpectedHeaders,
    parse: fn(List(String)) -> Result(#(a, List(String)), ParsingError),
    strict_columns: Bool,
    trim_whitespace: #(Bool, Bool),
  )
}

/// A data type specifying what headers the `Parser` is to expect.
/// 
/// Not certain it is the final version yet.
/// 
pub type ExpectedHeaders {
  Skip
  // Doesn't matter what the first row is, just skip it
  Empty
  // Expect the file to start with the data 
  InOrderExact(List(String))
  // Expect the first row of headers to be **exactly** in this order, with **exactly** these elements
  UnorderedExact(List(String))
  // Expect the first row of headers to have **exactly** these elements, but in whatever order
  InOrderCustom(List(fn(String) -> Bool))
  // Expect the first row of headers to return `True` when tested with the provided functions, in **exact** order.
  // UnorderedCustom(List(fn(String) -> Bool))
  // Expect the first row of headers to all return `True` to at least one of the provided functions, in whatever order
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
/// To build the parser, transform it using the [[parse.html#column|`parse.column`]]
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
/// `parse.column` function.
/// 
pub fn build(f: fn(a) -> b) -> Parser(fn(a) -> b) {
  Parser(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    expect_headers: Empty,
    parse: fn(tokens: List(String)) -> Result(
      #(fn(a) -> b, List(String)),
      ParsingError,
    ) {
      Ok(#(f, tokens))
    },
    strict_columns: False,
    trim_whitespace: #(True, True),
  )
}

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
///   // Parser(a)
/// ```
/// 
pub fn column(
  parser: Parser(fn(a) -> b),
  parse: fn(String) -> Result(a, Nil),
) -> Parser(b) {
  Parser(..parser, parse: fn(tokens: List(String)) {
    use #(constructor, remaining_tokens) <- result.try(parser.parse(tokens))

    // This case ends up being run when the parser is running.
    // So, if the list ends up empty, that means that one row has too few elements
    // to build the expected data type.
    case remaining_tokens {
      [token, ..rest] ->
        // TODO: Should I process the elements here, or no? I'm not sure
        token
        |> parse()
        |> result.map_error(fn(_) {
          CantParseRow(-1, token, "idk, think of a better error system.")
        })
        |> result.map(constructor)
        |> result.map(fn(b) { #(b, rest) })

      [] -> Error(RanOutOfValues)
    }
  })
}

/// Configure the parser to treat the first parsed row as the headers,
/// and specify that we expect the CSV headers to equal these headers.
/// 
/// If the first row is not **strictly identical** to the contents of
/// the arguments to this function, the parser will return an `Error`.
/// 
/// 
pub fn set_expected_headers(
  parser: Parser(a),
  headers: ExpectedHeaders,
) -> Parser(a) {
  Parser(..parser, expect_headers: headers)
}

/// > **This function is deprecated, and should be replaced with the
///   [[parse.html#set_expected_headers|`set_expected_headers`]] function.**
/// 
/// Configure the parser to treat the first parsed row as the headers,
/// and specify that we expect the CSV headers to equal these headers.
/// 
/// If the first row is not **strictly identical** to the contents of
/// the arguments to this function, the parser will return an `Error`.
/// 
/// ## Note
/// To replace this function with the `set_expected_headers` while preserving
/// behaviour, call it like so:
/// ```gleam
/// // change from
/// |> parse.expect_headers(["some", "headers"])
/// // to
/// |> parse.set_expected_headers(InOrderExact(["some", "headers"]))
/// ```
/// For more information, see the documentation of the function in question.
/// 
@deprecated("
A new function, `set_expected_headers` was created, with extended functionality and more documentation.
For new code, use that one.
")
pub fn expect_headers(parser: Parser(a), headers: List(String)) -> Parser(a) {
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
pub fn set_row_sep(parser: Parser(a), new_row_separator: String) -> Parser(a) {
  Parser(..parser, row_separator: new_row_separator)
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
pub fn set_escaper(parser: Parser(a), new_escaper: String) -> Parser(a) {
  Parser(..parser, escaper: new_escaper)
}

/// Function to set whether the parser should trim the whitespace on both ends of each value.
/// This operation is performed **before** the contents of the cell are parsed using the
/// functions from [[parse.html#column|`parse.column`]].
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
/// you pass to the [[parse.html#column|`parse.column`]] function.
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
  parser: Parser(a),
  start trim_start: Bool,
  end trim_end: Bool,
) -> Parser(a) {
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
  parser: Parser(a),
  new_column_separator: String,
) -> Parser(a) {
  Parser(..parser, column_separator: new_column_separator)
}

/// Function to make the parser strict in terms of columns.
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
pub fn set_strict_columns(parser: Parser(a)) -> Parser(a) {
  Parser(..parser, strict_columns: True)
}

/// Internal helper function to check whether the CSV headers that were found match
/// the expected pattern that was specified in the Parser building process.
/// 
fn process_headers(
  expected: ExpectedHeaders,
  found: List(String),
) -> Result(HeaderAction, ParsingError) {
  let match = fn(passed: Bool) -> Result(HeaderAction, ParsingError) {
    case passed {
      True -> Ok(SkipFirstRow)
      False -> Error(ExpectedHeadersMismatch(expected, found))
    }
  }

  case expected {
    Skip -> Ok(SkipFirstRow)
    Empty -> Ok(ParseFirstRow)
    InOrderExact(ordered_exact) -> { ordered_exact == found } |> match()
    UnorderedExact(unordered_exact) ->
      found
      |> list.all(list.contains(unordered_exact, _))
      |> match()
    InOrderCustom(ordered_custom) -> {
      {
        { list.length(ordered_custom) <= list.length(found) }
        || list.map2(
          ordered_custom,
          found,
          fn(fun: fn(String) -> Bool, val: String) -> Bool { fun(val) },
        )
        |> list.all(function.identity)
      }
      |> match()
    }
    // UnorderedCustom(_) -> todo
  }
}

/// Internal function for creating a row splitting function directly from a `Parser`.
/// 
fn make_row_splitter(parser: Parser(a)) -> fn(String) -> List(String) {
  util.split_on_unescaped(
    separator: parser.row_separator,
    not_in: parser.escaper,
  )
}

/// Internal function for creating a column splitting function directly from a `Parser`.
/// 
fn make_column_splitter(parser: Parser(a)) -> fn(String) -> List(String) {
  util.split_on_unescaped(
    separator: parser.column_separator,
    not_in: parser.escaper,
  )
}

/// Internal function for creating a trimming function directly from a `Parser`.
/// 
fn make_content_trimmer(parser: Parser(a)) -> fn(String) -> String {
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
  parser: Parser(a),
) -> fn(String) -> Result(String, ParsingError) {
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
      util.count_non_overlapping(escaper, unwrapped),
      // Count single escapers
      util.count_non_overlapping(escaper <> escaper, unwrapped),
      // Count duplicated
    )
  }

  // This might be overkill. Maybe instead of insisting on doing things with functional patterns
  // I should bite the bullet and do things like this by just consuming the String one character
  // at a time with a state machine implemented with recursive functions.
  fn(cell: String) -> Result(String, ParsingError) {
    // First trim the whitespace from the cell, so if the CSV String was modified (such as aligning the columns)
    // it will not affect this program from correctly unescaping cells.
    let trimmed = string.trim(cell)
    // Count the number of escapers in the cell
    let #(num_single, num_duplicated) = count(trimmed)

    // Check if the number of escapers in the cell is even
    case num_single, starts(trimmed), ends(trimmed) {
      n, _, _ if n % 2 != 0 ->
        Error(MalformedCell(cell, "Odd number of escapers"))
      n, True, True if n % 2 == 0 && n == num_duplicated * 2 ->
        // If it was even and wrapped in escapers, remove them along with the whitespace wrapping the cell
        Ok(deduplicate(trimmed))
      n, False, False if n == 0 && num_duplicated == 0 -> Ok(cell)
      n, False, False if n != 0 ->
        Error(MalformedCell(cell, "Unescaped internal escapers"))
      n, _, _ if n != num_duplicated * 2 ->
        // If the cell starts with an escaper but does not end in one, then something went wrong,
        // and we are returning an error.
        Error(MalformedCell(cell, "Wrongly duplicated internal escapers"))
      _, _, _ ->
        // If the cell starts with an escaper but does not end in one, then something went wrong,
        // and we are returning an error.
        Error(MalformedCell(cell, "Mismatched escapers"))
    }
  }
}

/// Internal function for creating a finalizer function that takes in the parsed
/// value along with the leftover tokens, and returns a `Result(a, ParsingError)`.
/// 
fn make_finalizer(
  parser: Parser(a),
) -> fn(#(a, List(String))) -> Result(a, ParsingError) {
  case parser.strict_columns {
    True -> fn(output: #(a, List(String))) -> Result(a, ParsingError) {
      let #(value, leftovers) = output
      case leftovers {
        // Strict columns and no leftovers, proceed
        [] -> Ok(value)
        // Strict columns and found leftovers, Error
        _ -> Error(StrictParsedWithLeftovers(leftovers))
      }
    }
    False -> fn(output: #(a, List(String))) -> Result(a, ParsingError) {
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
/// - `Ok(#(List(#(String, String)), Parser(a), String))` if the headers did match.
/// 
/// In the case of an `Ok`, the values are like so:
/// - The first `List(#(String, String))` is the list of metadata at the beginning. Right now,
///   if the user wants to do something with it, they must do so manually.
/// - Second element `Parser(a)` - a modified parser to use when calling the
///   [[parse.html#run|`parse.run`]] function later - it will expect that the first row
///   is the first data point, and will behave accordingly.
/// - The third element `String` is the contents of the CSV file with the metadata and header
///   row removed, which is what should go into the [[parse.html#run|`parse.run`]] function later.
///   If you for some reason want to use `mesv` only for processing metadata, you could discard
///   everything else and parse this `String` with another library.
/// 
/// As of right now, the frontmatter metadata can only be parsed if it follows the grammar
/// `key sep value newline`, where `sep` is by default `:` and `newline` is the same as the
/// CSV newline.
/// 
/// Read more about this on the [[mesv-grammar.html|MESV grammar]] page.
/// 
pub fn preprocess(
  parser: Parser(a),
  source: String,
) -> Result(#(List(#(String, String)), Parser(a), String), String) {
  // To do this, I need to:
  // 1. Done
  // 2. Separate the header parsing logic into its' own function as well
  // 3. Traverse through the source argument passed in to this function row by row
  //    - If the first row is not the start of metadata, just process it as the headers and move on
  //    - If the first row is made up of three hyphens, traverse the source row by row, parsing
  //      the contents as metadata, until the row marking the end (again three hyphens).
  //      Then modify the parser to expect the string to start with data, return the rest of the
  //      string, and the List of tuples made up of `key-value` pairs as the metadata.
  // Based on the Parser settings, errors when parsing metadata can be either ignored or cause
  // an early return with an `Error`.
  // Implement this
  todo
}

/// Function to use the specified `Parser(a)` to transform the `source` into a
/// `Result(List(Result(a, ParsingError)))`.
/// 
/// If the headers specified in the [[parse.html#expect_headers|`expect_headers`]] function did
/// not match the first row contents, a `ParsingError` will be returned, of the type
/// `ExpectedHeadersMismatch`, containing both the expected headers and what was found.
/// 
/// If the headers weren't specified, or were specified and match the expected pattern,
/// the function will return `Ok(List(Result(a, ParsingError)))`.
/// 
/// If you need a simple way to get the `List(a)` out of that, use the
/// [[parse.html#get_parsed|`get_parsed`]] function.
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
///    [[parse.html#split_on_unescaped|`split_on_unescaped`]] helper function.
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
///      [[parse.html#set_trim_whitespace|`set_trim_whitespace`]] function
///    - Parse the row by passing in the contents of the cells to the parsing functions from
///      [[parse.html#column|`parse.column`]], then if they return `Ok`, passing in the output
///      to the curried constructor function passed into the [[parse.html#build|`parse.build`]]
///      function
/// 4. Return a `List(Result(a, ParsingError))` and wrap it in `Ok`
/// 
pub fn run(
  parser: Parser(a),
  source: String,
) -> Result(List(Result(a, ParsingError)), ParsingError) {
  case make_row_splitter(parser)(source) {
    // Empty file - just return an empty list.
    [] -> Ok([])
    [found_headers, ..contents] -> {
      // If the headers are the same as expected, or the user didn't care and didn't specify them, they are in this value.
      // But if they weren't as expected, this use statement means the rest of the function is not executed.
      use header_action <- result.try(process_headers(
        parser.expect_headers,
        make_column_splitter(parser)(found_headers),
      ))

      // A locally defined function capturing the parser data, that is used for processing each row
      let process_row = fn(cells: List(String)) -> Result(a, ParsingError) {
        cells
        // Unescape the String - ie, if the escape characters are present both at the beginning
        // and end of the String, remove them, and deduplicate any internal escapers.
        // If only one end of the String has an escaper, throw a Parsing error for this row.
        |> list.map(make_unescaper(parser))
        // Only proceed if all cells in this row are unwrapped
        |> result.all()
        |> result.try(fn(elements: List(String)) -> Result(a, ParsingError) {
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

      // At this point, the `Ok` output is guaranteed, even if parsing of every single row
      // fails, and the `List(a)` is empty.
      // So just map over the `List(String)` of rows and try to parse each of them,
      // and then partition the `List(Result(a, ParsingError))` into `#(List(a), List(ParsingError))`
      Ok(
        // A hacky solution to append the first line to the contents if the `process_headers`
        // function returned decided that we should parse the first row.
        case header_action {
          ParseFirstRow -> [found_headers, ..contents]
          SkipFirstRow -> contents
        }
        |> list.map(fn(row_string) {
          // All of the parsing functions are condensed here to avoid having to map multiple times.
          row_string
          |> make_column_splitter(parser)
          |> process_row()
        }),
      )
    }
  }
}

/// > **This function is deprecated, and should be replaced with the
///   [[parse.html#run|`run`]] function.**
/// 
/// Function to use the specified `Parser(a)` to transform the source into a `#(List(a),
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
  parser: Parser(a),
  source: String,
) -> Result(#(List(a), List(ParsingError)), ParsingError) {
  run(parser, source)
  |> result.map(fn(rows) {
    rows
    |> result.partition
    |> pair.map_first(list.reverse)
    |> pair.map_second(list.reverse)
  })
}

/// Helper function to easily extract the successfully parsed rows from the output of
/// the [[parse.html#run|`parse.run`]] function.
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
pub fn get_parsed(rows: List(Result(a, ParsingError))) -> List(a) {
  rows
  |> list.filter_map(fn(val: Result(a, ParsingError)) -> Result(a, Nil) {
    case val {
      Ok(parsed_val) -> Ok(parsed_val)
      Error(_) -> Error(Nil)
    }
  })
}
