# mesv

[![Package Version](https://img.shields.io/hexpm/v/mesv)](https://hex.pm/packages/mesv)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mesv/)

A type-focused CSV parsing and formatting library with extensive configuration options and documentation examples.

I wanted the name to be short and a single word, because I dislike snake_case. Adding the fact that one of the (planned) features of this library was adding
frontmatter metadata to the generated CSV file, I somehow mangled the two words `metadata` and `csv`, and eventually arrived at `mesv`.

### Important!
This library is still in active development, and although it's functional (check the unit tests to make sure), the types, function names, signatures, and behaviours
are liable to change between minor versions until version `1.0.0`.

If you do end up using this library, be careful when updating to avoid sudden changes!

## Installation
To use in your project, use the `gleam` command line tool to add `mesv`.
```bash
gleam add mesv
```

# Examples
Basic examples of both formatting (converting data to String) and parsing (reading String and converting to some data type).

## Formatting
As formatting is the simpler use case of the two available, I will go over it first.

To generate a default CSV file from some data, you first need to create a `Formatter`.
To do so, simply call the `format.build` function and pass in a function that converts your data type to a `List(String)`.

```gleam
import gleam/int
import mesv/format

const data: List(#(String, Int, Bool)) = [
  #("Adam", 20, True),
  #("Beatrice", 25, True),
  #("Colin", 2, False),
]

pub fn main() -> Nil {
  let formatter =
    // First create a formatter
    format.build(fn(val: #(String, Int, Bool)) -> List(String) {
      let #(name, age, adult) = val
      [
        name,
        int.to_string(age),
        case adult {
          True -> "true"
          False -> "false"
        },
      ]
    })

  // Then, use that formatter on the data you want to format
  let formatted_data = format.format(formatter, data)

  // By default, the formatter uses the comma as a column separator,
  // newline as the row separator, and doublequotes for escaping cells
  assert formatted_data == "Adam,20,true\nBeatrice,25,true\nColin,2,false"
}
```
Then just call the `format.format` function using your `Formatter` to convert a `List` of data into a String.

### Setting custom separators and escapers
As mentioned in the comments of the above example, the `Formatter` is initialized with some default values.

Specifically:
- `,` is used as the column separator
- `\n` is used as the row separator
- `"` is used as the escaper, to wrap cells that contain separators or escapers inside

However, all of these can be changed using the `set_` functions.

```gleam
// Setup code is hidden to reduce bloat

pub fn main() -> Nil {
  let formatter =
    // [...]
    |> format.set_col_sep("|")
    |> format.set_row_sep(";")
    |> format.set_escaper("'") // Effect not visible here

  let formatted_data = format.format(formatter, data)

  // As you can see, the formatted CSV is different,
  // though the data is identical.
  assert formatted_data == "Adam|20|true;Beatrice|25|true;Colin|2|false"
}
```

### When are cells escaped?
By default, cells are only escaped (wrapped in escapers) if they contain a separator or an escaper.

In addition, if a cell contains an escaper, it is then replaced with two escapers, to maintain an even number.
```gleam
import mesv/format

const data: List(#(String, String)) = [
  #("Adam", "Cool"),
  #("Beatrice", "It's |neat|"),
  #("Colin", "I guess it's fine;"),
]

pub fn main() -> Nil {
  let formatted_data =
    format.build(fn(val: #(String, String)) -> List(String) { [val.0, val.1] })
    |> format.set_col_sep("|")
    |> format.set_row_sep(";")
    |> format.set_escaper("'")
    |> format.format(data)

  // Only cells that need to be escaped will be wrapped in escapers.
  assert formatted_data
    == "Adam|Cool;Beatrice|'It''s |neat|';Colin|'I guess it''s fine;'"
}
```

Using the function `format.set_escape_all`, it's possible to make a formatter that escapes all cells. However, I don't know where this would be useful - I added it because I was on a roll, without thinking too much.

### Headers
By default, the output will not contain headers - however, you can set headers by using the `format.set_headers` function and passing in a `List(String)`, which will
be prepended to the CSV String, joined with the column separators and appropriately escaped if necessary.

```gleam
// [...]

const data: List(#(String, Int, Bool)) = [
  #("Adam", 20, True),
  #("Beatrice", 25, True),
  #("Colin", 2, False),
]

pub fn main() -> Nil {
  let formatted_data =
    // [...]
    |> format.set_headers(["Name", "Age", "Is an adult"])
    // ^ Setting headers 
    |> format.format(data)

  // The specified headers are prepended to the CSV string
  assert formatted_data
    == "Name,Age,Is an adult\nAdam,20,true\nBeatrice,25,true\nColin,2,false"
}
```

## Parsing
Parsing CSV is a bit more complicated, as for all data types other than `String`, it's necessary to account for failing to parse a specific cell.

However, most of this behaviour is hidden away in the internal functions, so usage is relatively easy.

```gleam
import gleam/int
import mesv
import mesv/parse

const expected_data: List(#(String, Int, Bool)) = [
  #("Adam", 20, True),
  #("Beatrice", 25, True),
  #("Colin", 2, False),
]

pub fn main() -> Nil {
  let parsed_data =
    parse.build({
      // Create a parsing function using `mesv.parsed`
      // to construct a curried parsing function
      use name <- mesv.parsed
      use age <- mesv.parsed
      use adult <- mesv.parsed

      // If any value fails (ie, returns Error(Nil)),
      // the parsing of a row will stop.
      // However, if it reaches here,
      // it returns the following data type
      #(name, age, adult)
    })
    |> parse.column(Ok)
    |> parse.column(int.parse)
    |> parse.column(fn(val: String) -> Result(Bool, Nil) {
      case val {
        "true" -> Ok(True)
        "false" -> Ok(False)
        _ -> Error(Nil)
      }
    })
    // Pass in the CSV String to parse
    |> parse.parse(
      "Adam,20,true\nBeatrice,25,true\nColin,2,false",
    )

  // The returned data is wrapped a bit weirdly, which I'm considering changing
  assert parsed_data == Ok(#(expected_data, []))
}
```

First, use the `parse.build` function to construct a `Parser`. This function expects a curried function - that is, a function that returns a function -
with as many arguments as there are inputs to construct the final output.

Then, call `parse.column` to specify a function to use when parsing that column, and transform the `Parser` into one where one argument is filled.

It is possible to call `parse.parse` using a `Parser` without any columns specified - however, doing so would result in a List of curried functions without any data inside.

In the above example, the succesive functions do this:
1. First, `parse.build` creates a `Parser(fn(String) -> fn(Int) -> fn(Bool) -> #(String, Int, Bool))`.
2. Then, `parse.column` specifies that to transform the first element of a row from `String` to `Result(String, Nil)`, use the function `Ok`.
3. The next `parse.column` says that to turn the second element from `String` to `Result(Int, Nil)`, use the function `int.parse`.
4. The last `parse.column` is a custom one for parsing `Bool` - Return `Ok(Bool)` for `true` or `false`, and `Error(Nil)` for anything else.
5. Then, call the `parse.parse` function to use the above specified functions on each row, and if they succeed transform them into the specified data type, `#(String, Int, Bool)`.

### Headers
As in the Formatting section, handling headers is one of the features of `mesv`.

Specifically, if you know that the first row is going to be headers, you can specify what you expect they will be - then, if they don't match, the parser will return an `Error(ExpectedHeadersMismatch)`.
```gleam
// expected_data is identical
pub fn main() -> Nil {
  let parsed_data =
    // [...] parser is the exact same
    // Specify that the first row is the headers,
    // and if they don't match what is specified, 
    // the parsing will fail
    |> parse.expect_headers(["Name", "Age", "Is an adult"])
    |> parse.parse(
      "Name,Age,Is an adult\n"
      <> "Adam,20,true\n"
      <> "Beatrice,25,true\n"
      <> "Colin,2,false",
    )

  assert parsed_data == Ok(#(expected_data, []))
}
```

To add to the above explanation, this would be inserting a step between 4 and 5:
5. The `parse.expect_headers` says to the parser that the first row will be headers, and that they should be identical to what is passed in. If they aren't, the parsing returns an `Error`.

### Setting custom separators and escapers
Just as with a formatter, a parser can also be configured to expect custom colum and row separators, and escapers.

It is important to mention however, that while row and column separators can be whatever character or word you want, for escapers, there is some ambiguity.

According to the [CSV specification](https://www.ietf.org/rfc/rfc4180.txt), the grammar of a CSV file specifies that if a cell (or field, as it's referred to) is escaped, it means that
there are single doublequotes (escapers) on both sides, and if any doublequotes(escapers) appear inside of the cell, they should appear doubled.

And here lies the issue - when changing the escaper to be a single character, there is no ambiguity - when doubling a single character, there are two characters.

But imagine that you set the escaper to be `==`. Now, as per the specification, if an instance of the escaper appears within a cell, it must be duplicated. So, take for example the cell `a==b`.
Then, to escape it, wrap it in escapers and duplicate the instance of the escaper inside.

So, should that be `==a====b==`, or `==a===b==`? When trying to count instances of the escaper in the first one, there are 5, because there are three ways to find `==` in `====`.
But then, if it were the second, it doesn't really follow the specification either.

I'm sure there does exist a foolproof and reliable method of escaping cells with multi-character escapers, but I haven't found one, and I don't think there is need of it.

**Tldr;** use single character escapers.

### Notes
The `parse.parse` function returns a rather strange type, that being `Result(#(List(a), List(parse.ParsingError)), parse.ParsingError)`.
This structure is liable to change, as I'm not very happy with how I handled parsing errors.

However, to explain it a bit - if the `Parser` had headers specified using `expect_headers` function and the first row didn't match the expected values, an `Error(ExpectedHeadersMismatch)` value is returned.
If they did match or were not specified, the function will always return an `Ok` value.

In that `Ok` value is a tuple of lists. The first list is the list of successfully parsed rows, and the second list is the errors returned for each row that failed to parse.

Specifically, these two lists are obtained through calling the `result.partition` function on a `List(Result(a, parse.ParsingError))`, then reversing the two lists (since partition returns them in reverse order).

## Documentation
Further documentation can be found at [hexdocs/mesv](https://hexdocs.pm/mesv), in the descriptions of the relevant modules.

## Roadmap
As mentioned several times in this README, this project is still rather young, and there are several features I still want to implement - first among them the namesake of this library, adding metadata.

Here is a roadmap, describing the planned features:

- Alpha     (0.1.0) - **Done!** Basic features, a usable library for parsing CSV
- Beta      (0.2.0) - Typed frontmatter support, features to change parsing behaviour depending on metadata
- Release   (1.0.0) - Finalized types and error handling, two-in-one constructors (create formatter and parser using the same builder), feature for column-based cell parsing in addition to order-based
- Streaming (1.1.0) - Support for stream-based inputs and outputs to reduce the memory requirements for large files
