import gleam/function
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import util

/// An error type representing any kind of error encountered when parsing.
/// 
/// ### Type definition
/// ```gleam
/// pub type ParsingError {
///   CantParseRow(index: Int, contents: String, reason: String)
///   ExpectedHeadersMismatch(expected: List(String), found: List(String))
///   RanOutOfValues
///   StrictParsedWithLeftovers(leftovers: List(String))
///   EncounteredMalformedElement(element: String, description: String)
/// }
/// ```
/// 
pub type ParsingError {
  CantParseRow(index: Int, contents: String, reason: String)
  ExpectedHeadersMismatch(expected: List(String), found: List(String))
  RanOutOfValues
  StrictParsedWithLeftovers(leftovers: List(String))
  EncounteredMalformedElement(element: String, description: String)
}

/// The type describing how to create a value of type `a` from a String.
/// 
/// To create it, use the `build` function, the provided transformation functions
/// (`set_row_sep`, `set_col_sep`, `expect_headers`, `set_escaper`) to configure the specific behaviour,
/// and the `column` function to specify how each subsequent column should be parsed.
/// 
/// Once you have the desired `Parser(a)`, use the `parse` function to convert a `String` into a `List(a)` (plus a list of `ParsingError`s).
/// 
pub opaque type Parser(a) {
  Parser(
    column_separator: String,
    row_separator: String,
    escaper: String,
    expect_headers: Option(List(String)),
    parse: fn(List(String)) -> Result(#(a, List(String)), ParsingError),
    strict_columns: Bool,
    trim_whitespace: #(Bool, Bool),
  )
}

/// Function for directly building a `Parser` that uses the subsequent elements in order
/// 
/// ### Function Declaration
/// ```gleam
/// build(f: fn(a) -> b) -> Parser(fn(a) -> b)
/// ```
/// 
pub fn build(f: fn(a) -> b) -> Parser(fn(a) -> b) {
  Parser(
    column_separator: ",",
    row_separator: "\n",
    escaper: "\"",
    expect_headers: None,
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

/// Function to build a `Parser`, by passing in a parsing function for a specified column.
/// 
/// ### Function Declaration
/// ```gleam
/// column(parser: Parser(fn(a) -> b), parse: fn(String) -> Result(a, ParsingError)) -> Parser(b)
/// ```
/// 
pub fn column(
  parser: Parser(fn(a) -> b),
  parse: fn(String) -> Result(a, ParsingError),
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
        |> result.map(constructor)
        |> result.map(fn(b) { #(b, rest) })

      [] -> Error(RanOutOfValues)
    }
  })
}

/// Function to specify that we expect the CSV headers to follow this exact format.
/// 
/// ### Function Declaration
/// ```gleam
/// expect_headers(parser: Parser(a), headers: List(String)) -> Parser(a)
/// ```
/// 
pub fn expect_headers(parser: Parser(a), headers: List(String)) -> Parser(a) {
  Parser(..parser, expect_headers: Some(headers))
}

/// Function to set a specific row separator, instead of the default newline (`\n`)
/// 
/// ### Function Declaration
/// ```gleam
/// set_row_sep(parser: Parser(a), new_row_separator: String) -> Parser(a)
/// ```
/// 
pub fn set_row_sep(parser: Parser(a), new_row_separator: String) -> Parser(a) {
  Parser(..parser, row_separator: new_row_separator)
}

/// Function to set a specific value escaper, instead of the default doublequotes (`"`)
/// 
/// ### Function Declaration
/// ```gleam
/// set_escaper(parser: Parser(a), new_escaper: String) -> Parser(a)
/// ```
/// 
pub fn set_escaper(parser: Parser(a), new_escaper: String) -> Parser(a) {
  Parser(..parser, escaper: new_escaper)
}

/// Function to set whether the parser should trim the whitespace on both ends of each value.
/// 
/// ### Function Declaration
/// ```gleam
/// set_trim_whitespace(parser: Parser(a), trim_start: Bool, trim_end: Bool) -> Parser(a)
/// ```
/// 
pub fn set_trim_whitespace(
  parser: Parser(a),
  trim_start: Bool,
  trim_end: Bool,
) -> Parser(a) {
  Parser(..parser, trim_whitespace: #(trim_start, trim_end))
}

/// Function to set a specific column separator, instead of the default comma (`,`)
///
/// ### Function Declaration
/// ```gleam
/// set_col_sep(parser: Parser(a), new_column_separator: String) -> Parser(a)
/// ```
/// 
pub fn set_col_sep(
  parser: Parser(a),
  new_column_separator: String,
) -> Parser(a) {
  Parser(..parser, column_separator: new_column_separator)
}

/// Function to use the specified `Parser(a)` to transform the source into a `List(a)`
/// 
/// ### Function Declaration
/// ```gleam
/// parse(parser: Parser(a), source: String) -> Result(#(List(a), List(ParsingError)), ParsingError)
/// ```
/// 
/// If the headers specified in the `expect_headers` function did not match the specified pattern, a `ParsingError` will be returned,
/// of the type `ExpectedHeadersMismatch`, containing both the expected headers, and what was found.
/// 
/// If the headers weren't specified, or were specified and match the expected pattern, the function will return `Ok(#(List(parsed_type), List(ParsingError)))`;
/// The first is the list of all rows that were successfully parsed, while the second is a list of `ParsingError`s that were thrown due to
/// a row failing to parse.
/// 
/// What to do with both of these Lists is up to the user, whether to ignore all errors or abort if any errors occur.
/// 
pub fn parse(
  parser: Parser(a),
  source: String,
) -> Result(#(List(a), List(ParsingError)), ParsingError) {
  let Parser(
    column_separator,
    row_separator,
    escaper,
    headers,
    parse,
    strict_columns,
    #(trim_start, trim_end),
  ) = parser

  let split_rows =
    partition_on_unescaped_(separator: row_separator, not_in: escaper)

  case split_rows(source) {
    [] -> Ok(#([], []))
    [found_headers, ..contents] -> {
      // A local instance of the `partition_on_unescaped_` function, specifically for splitting columns
      let split_columns =
        partition_on_unescaped_(separator: column_separator, not_in: escaper)

      let trim_whitespace = fn(element: String) -> String {
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

      let unwrap = fn(element: String) -> Result(String, ParsingError) {
        case
          string.starts_with(element, escaper),
          string.ends_with(element, escaper)
        {
          True, True ->
            Ok(
              element
              |> string.remove_prefix(escaper)
              |> string.remove_suffix(escaper),
            )
          False, False -> Ok(element)
          _, _ ->
            Error(EncounteredMalformedElement(element, "Mismatched escapers"))
        }
      }

      let unescape = unescape([#(escaper, escaper <> escaper)])

      // If the headers are the same as expected, or the user didn't care and didn't specify them, they are in this value.
      // But if they weren't as expected, this use statement means the rest of the function is not executed.
      use _headers <- result.try(process_headers(
        headers,
        split_columns(found_headers),
      ))

      // A locally defined function capturing the parser data, that is used for processing each row
      let process_row = fn(elements: List(String)) -> Result(a, ParsingError) {
        elements
        // Trim white space according to the rules set.
        // It's before the unwrap steps in case the CSV file was modified, for example to align the columns
        |> list.map(trim_whitespace)
        // Unwrap the String - ie, if the escape characters are present both at the beginning
        // and end of the String, remove them.
        // If only one end of the String has an escaper, throw a Parsing error for this row.
        |> list.map(unwrap)
        |> result.all()
        |> result.try(fn(elements: List(String)) -> Result(a, ParsingError) {
          elements
          // Unescape the String - for now, just deduplicate the escaper characters
          // (According to the CSV format standard, if any doubleQuotes appear inside a cell,
          // they must be replaced with two of them, and the entire cell wrapped)
          |> list.map(unescape)
          // Call the Parsing function to convert the `List(String)` of elements (already unescaped and unwrapped)
          // to try and convert it into the desired data type `a`.
          |> parse()
          // If the parsing step succeeded, check whether there were any leftovers,
          // and depending on the parser settings, either proceed or throw an error.
          |> result.try(fn(output: #(a, List(String))) -> Result(
            a,
            ParsingError,
          ) {
            let #(value, leftovers) = output
            case strict_columns, leftovers {
              False, _ -> Ok(value)
              True, [] -> Ok(value)
              True, _ -> Error(StrictParsedWithLeftovers(leftovers))
            }
          })
        })
      }

      // At this point, the `Ok` output is guaranteed, even if parsing of every single row
      // fails, and the `List(a)` is empty.
      // So just map over the `List(String)` of rows and try to parse each of them,
      // and then partition the `List(Result(a, ParsingError))` into `#(List(a), List(ParsingError))`
      Ok(
        // A hacky solution to append the first line to the contents if the user didn't provide
        // an expected header pattern.
        case headers {
          Some(_) -> contents
          None -> [found_headers, ..contents]
        }
        |> list.map(fn(row_string) {
          // All of the parsing functions are condensed here to avoid having to map multiple times.
          row_string
          |> split_columns()
          |> process_row()
        })
        // Fucking hell, the partitiion function reverses the order of both lists. Without testing I would have missed this bug
        |> result.partition()
        |> pair.map_first(list.reverse)
        |> pair.map_second(list.reverse),
      )
    }
  }
}

/// Internal helper function for creating a function for 'unescaping' an element
/// (for each `rule`, replacing the second element in the tuple with the first).
/// 
/// ### Function Declaration
/// ```gleam
/// unescape(rules: List(#(String, String))) -> fn(String) -> String
/// ```
/// 
/// This function takes in a String that is guaranteed to be a value - that is, it's either unescaped,
/// or it starts with an escaper and ends with an escaper.
/// 
/// It's a curried function because I like functional programming, and because it *should* give some performance improvements
/// if I create such a function before any looping instead of constructing one for each iteration.
/// 
fn unescape(rules: List(#(String, String))) -> fn(String) -> String {
  fn(el: String) -> String {
    rules
    |> list.map(fn(rule: #(String, String)) -> fn(String) -> String {
      string.replace(each: rule.1, with: rule.0, in: _)
    })
    |> list.fold(el, fn(acc: String, rule: fn(String) -> String) -> String {
      rule(acc)
    })
  }
}

/// Internal helper function to check whether the CSV headers that were found match the expected pattern that was specified
/// in the Parser building process.
/// 
/// ### Function Declaration
/// ```gleam
/// process_headers(expected: Option(List(String)), found: List(String)) -> Result(List(String), ParsingError)
/// ```
/// 
fn process_headers(
  expected: Option(List(String)),
  found: List(String),
) -> Result(List(String), ParsingError) {
  case expected {
    Some(pattern) ->
      case found == pattern {
        True -> Ok(found)
        False -> Error(ExpectedHeadersMismatch(pattern, found))
      }
    None -> Ok(found)
  }
}

/// Internal helper function for constructing a function that splits a `String` on `el`, as long as the `el` is not between two `not_in`.
/// 
/// ### Function Declaration
/// ```gleam
/// partition_on_unescaped_(separator el: String, not_in escaper: String) -> fn(String) -> List(String)
/// ```
/// 
pub fn partition_on_unescaped_(
  separator el: String,
  not_in escaper: String,
) -> fn(String) -> List(String) {
  // TODO : Maybe instead of checking for escapers on both the beginning and the end, we should count the number of escapers and check if it's an even number?
  // Since according to the [CSV specification](https://www.ietf.org/rfc/rfc4180.txt), the syntax of the format ensures that for every element,
  // the doubleQuotes that are used as escapers must be even.
  // Yep, that is what should be done.
  // In case of row separators, the escaper can appear before the row separator but not be at the beginning of the string,
  // since the value that contains the row separator is not the first in that row.
  // However, in that case the count of escapers in the first part of the string will be odd, thus being the property we should check.
  fn(to_split: String) -> List(String) {
    to_split
    // First split the string on the separator
    |> string.split(on: el)
    // Then traverse the List and merge any two Strings that don't form a cell together
    |> util.list_merge_map(fn(first: String, second: String) -> Option(String) {
      // If the first string contains an odd number of escaper Strings, merge the two
      case util.count_occurences(of: escaper, in: first) % 2 == 1 {
        // I almost forgot to readd the separator when merging the strings.
        True -> Some(first <> el <> second)
        False -> None
      }
    })
  }
}
