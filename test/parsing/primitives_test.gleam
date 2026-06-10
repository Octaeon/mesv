//// A test module for testing the correctness of the `parse` primitives (parse.int,
//// parse.float, primitive.bool, etc) as well as their transformations (such as parse.list,
//// parse.tuple)
//// 

import gleam/function
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import mesv/parse.{CellParsingFailed, Text}
import mesv/parse/primitive.{ValueError}

pub fn integer_base_10_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.integer)
    |> parse.run(Text("1\n2\na\n1.2\n"))

  let expected = [
    Ok(1),
    Ok(2),
    Error(CellParsingFailed(
      "a",
      ValueError("a", ["Integer base 10"], [None], None),
    )),
    Error(CellParsingFailed(
      "1.2",
      ValueError(
        "1.2",
        ["Integer base 10"],
        [Some("For floating point numbers, use parse.float")],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "",
      ValueError("", ["Integer base 10"], [Some("Cell was empty")], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, base 10"
}

pub fn integer_base_2_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.integer_binary)
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
    |> parse.column(primitive.integer_hex)
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
      ValueError(
        "1.f",
        ["Integer base 16"],
        [Some("For floating point numbers, use parse.float")],
        None,
      ),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, base 16"
}

pub fn integer_arbitrary_base_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.integer_arbitrary_base(7))
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
      ValueError(
        "1.0",
        ["Integer base 7"],
        [Some("For floating point numbers, use parse.float")],
        None,
      ),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, arbitrary base"
}

pub fn float_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.float)
    |> parse.run(Text("1\n10\n100.1\n1.f\n.00001\n.10.0\n"))

  let expected = [
    Ok(1.0),
    Ok(10.0),
    Ok(100.1),
    Error(CellParsingFailed("1.f", ValueError("1.f", ["Float"], [None], None))),
    Ok(0.00001),
    Error(CellParsingFailed(
      ".10.0",
      ValueError(
        ".10.0",
        ["Float"],
        [Some("Found 3 dots in cell; Only 0 or 1 are allowed.")],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "",
      ValueError("", ["Float"], [Some("Cell was empty")], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Float"
}

pub fn character_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.char)
    |> parse.run(Text(
      "1\n2\na\n1.2\nthere can be whitespace\n   !   \nIt's just trimmed\n",
    ))

  let expected = [
    Ok("1"),
    Ok("2"),
    Ok("a"),
    Error(CellParsingFailed(
      "1.2",
      ValueError("1.2", ["Char"], [Some("Multiple characters")], None),
    )),
    Error(CellParsingFailed(
      "there can be whitespace",
      ValueError(
        "there can be whitespace",
        ["Char"],
        [Some("Multiple characters")],
        None,
      ),
    )),
    Ok("!"),
    Error(CellParsingFailed(
      "It's just trimmed",
      ValueError(
        "It's just trimmed",
        ["Char"],
        [Some("Multiple characters")],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "",
      ValueError("", ["Char"], [Some("Cell was empty")], None),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Integer, base 10"
}

pub fn optional_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.integer |> primitive.option())
    |> parse.run(Text("1\n\na\n1.2"))

  let expected = [
    Ok(Some(1)),
    Ok(None),
    Error(CellParsingFailed(
      "a",
      ValueError("a", ["Optional", "Integer base 10"], [None, None], None),
    )),
    Error(CellParsingFailed(
      "1.2",
      ValueError(
        "1.2",
        ["Optional", "Integer base 10"],
        [None, Some("For floating point numbers, use parse.float")],
        None,
      ),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | Optional parsing"
}

pub fn attempt_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.integer |> primitive.attempt())
    |> parse.run(Text("1\n\na\n1.2"))

  let expected = [
    Ok(Some(1)),
    Ok(None),
    Ok(None),
    Ok(None),
  ]

  assert parsed == expected as "Parsing Primitives | Attempt parsing"
}

pub fn map_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(primitive.integer |> primitive.map(fn(i) { i >= 18 }))
    |> parse.run(Text("1\n\n20\n21.2\na\n\"I'm an adult, I swear!\""))

  let expected = [
    Ok(False),
    Error(CellParsingFailed(
      "",
      ValueError(
        "",
        ["Map", "Integer base 10"],
        [None, Some("Cell was empty")],
        None,
      ),
    )),
    Ok(True),
    Error(CellParsingFailed(
      "21.2",
      ValueError(
        "21.2",
        ["Map", "Integer base 10"],
        [None, Some("For floating point numbers, use parse.float")],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "a",
      ValueError("a", ["Map", "Integer base 10"], [None, None], None),
    )),
    Error(CellParsingFailed(
      "I'm an adult, I swear!",
      ValueError(
        "I'm an adult, I swear!",
        ["Map", "Integer base 10"],
        [None, None],
        None,
      ),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | 'Map' transformation"
}

pub fn try_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(
      primitive.string
      |> primitive.try(fn(val) {
        val
        |> string.split_once(on: " ")
        |> result.map_error(fn(_) {
          ValueError(val, ["Split on space"], [Some("No space")], None)
        })
      }),
    )
    |> parse.run(Text("nope\nno_spaces_here\nokay have_one\nmaybe even two"))

  let expected = [
    Error(CellParsingFailed(
      "nope",
      ValueError(
        "nope",
        ["Try", "Split on space"],
        [None, Some("No space")],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "no_spaces_here",
      ValueError(
        "no_spaces_here",
        ["Try", "Split on space"],
        [None, Some("No space")],
        None,
      ),
    )),
    Ok(#("okay", "have_one")),
    Ok(#("maybe", "even two")),
  ]

  assert parsed == expected as "Parsing Primitives | 'Try' transformation"
}

pub fn list_basic_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(
      primitive.bool(False)
      |> primitive.array(#("[", "]"), "."),
    )
    |> parse.run(Text(
      "[true.false.true]\n[no.yes]\n[1.1.1.1]\n[True.1.False.0.Yes.NO]",
    ))

  let expected = [
    Ok([True, False, True]),
    Ok([False, True]),
    Ok([True, True, True, True]),
    Ok([True, True, False, False, True, False]),
  ]

  assert parsed == expected as "Parsing Primitives | List, basic"
}

pub fn list_basic_strict_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(
      primitive.bool(True)
      |> primitive.array(#("[", "]"), "."),
    )
    |> parse.run(Text(
      "[true.false.true]\n[no.yes]\n[1.1.1.1]\n[True.1.False.0.Yes.NO]",
    ))

  let expected = [
    Ok([True, False, True]),
    Error(CellParsingFailed(
      "[no.yes]",
      ValueError(
        "[no.yes]",
        ["Array", "Strict Bool"],
        [Some("Failed using parser [ \"Strict Bool\" ] on [no]"), None],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "[1.1.1.1]",
      ValueError(
        "[1.1.1.1]",
        ["Array", "Strict Bool"],
        [Some("Failed using parser [ \"Strict Bool\" ] on [1]"), None],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "[True.1.False.0.Yes.NO]",
      ValueError(
        "[True.1.False.0.Yes.NO]",
        ["Array", "Strict Bool"],
        [Some("Failed using parser [ \"Strict Bool\" ] on [1]"), None],
        None,
      ),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | List, basic strict"
}

pub fn list_basic_errors_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(
      primitive.bool(False)
      |> primitive.array(#("[", "]"), "."),
    )
    |> parse.run(Text("[  true.  false  .  true  ]\ntrue.true.true\n[.true]"))

  let expected = [
    Ok([True, False, True]),
    Error(CellParsingFailed(
      "true.true.true",
      ValueError(
        "true.true.true",
        ["Array"],
        [Some("Wasn't wrapped in delimiters #([, ])")],
        None,
      ),
    )),
    Error(CellParsingFailed(
      "[.true]",
      ValueError(
        "[.true]",
        ["Array", "Relaxed Bool"],
        [Some("Failed using parser [ \"Relaxed Bool\" ] on []"), None],
        None,
      ),
    )),
  ]

  assert parsed == expected as "Parsing Primitives | List, basic errors"
}

pub fn list_composite_parser_test() -> Nil {
  let parsed =
    parse.build(function.identity)
    |> parse.column(
      primitive.bool(True)
      |> primitive.attempt()
      |> primitive.array(#("[", "]"), "."),
    )
    |> parse.run(Text("[  true.  false  .  true  ]\ntrue.true.true\n[.true]"))

  let expected = [
    Ok([Some(True), Some(False), Some(True)]),
    Error(CellParsingFailed(
      "true.true.true",
      ValueError(
        "true.true.true",
        ["Array"],
        [Some("Wasn't wrapped in delimiters #([, ])")],
        None,
      ),
    )),
    Ok([None, Some(True)]),
  ]

  assert parsed == expected as "Parsing Primitives | List, composite parsers"
}
