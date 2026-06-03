# Mesv

[![Package Version](https://img.shields.io/hexpm/v/mesv)](https://hex.pm/packages/mesv)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mesv/)

A type-focused CSV parsing and formatting library with extensive configuration options and documentation examples.

I wanted the name to be short and a single word, because I dislike snake_case. Adding the fact that one of the (planned) features of this library was adding
frontmatter metadata to the generated CSV file, I somehow mangled the two words `metadata` and `csv`, and eventually arrived at `mesv`.

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
```

## Documentation
Further documentation can be found at [hexdocs/mesv](https://hexdocs.pm/mesv).
