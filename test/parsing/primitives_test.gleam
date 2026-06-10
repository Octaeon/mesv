//// A test module for testing the correctness of the `parse` primitives (parse.int,
//// parse.float, parse.bool, etc) as well as their transformations (such as parse.list,
//// parse.tuple)
//// 

import gleam/function
import gleam/option.{None}
import mesv/parse.{CellParsingFailed, Text, ValueError}

// Test:
// - Float
// - Characters
// - Strings (normal)
// - Optional values
// - Mapping parsers
// - Lists
// - Nested Lists

pub fn integer_base_10_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(parse.integer)
    |> parse.run(Text("1\n2\na\n1.2"))

  let expected = [
    Ok(1),
    Ok(2),
    Error(CellParsingFailed(
      "a",
      ValueError("a", ["Integer base 10"], [None], None),
    )),
    Error(CellParsingFailed(
      "1.2",
      ValueError("1.2", ["Integer base 10"], [None], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, base 10"
}

pub fn integer_base_2_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(parse.integer_binary)
    |> parse.run(Text("1\n10\n1001\n12"))

  let expected = [
    Ok(1),
    Ok(2),
    Ok(9),
    Error(CellParsingFailed(
      "12",
      ValueError("12", ["Integer base 2"], [None], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, base 2"
}

pub fn integer_base_16_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(parse.integer_hex)
    |> parse.run(Text("1\n10\n1001\nFF\nf\nF\n1.f"))

  let expected = [
    Ok(1),
    Ok(16),
    Ok(4097),
    Ok(255),
    Ok(15),
    Ok(15),
    Error(CellParsingFailed(
      "1.f",
      ValueError("1.f", ["Integer base 16"], [None], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, base 16"
}

pub fn integer_arbitrary_base_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(parse.integer_arbitrary_base(7))
    |> parse.run(Text("1\n10\n2004\nFF\n1.0"))

  let expected = [
    Ok(1),
    Ok(7),
    Ok(690),
    Error(CellParsingFailed(
      "FF",
      ValueError("FF", ["Integer base 7"], [None], None),
    )),
    Error(CellParsingFailed(
      "1.0",
      ValueError("1.0", ["Integer base 7"], [None], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, arbitrary base"
}

pub fn float_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(parse.float)
    |> parse.run(Text("1\n10\n100.1\n1.f\n.00001"))

  let expected = [
    Ok(1.0),
    Ok(10.0),
    Ok(100.1),
    Error(CellParsingFailed("1.f", ValueError("1.f", ["Float"], [None], None))),
    Error(CellParsingFailed(
      ".00001",
      ValueError(".00001", ["Float"], [None], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Float"
}
