import gleam/float
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mesv/util

/// The default `Error` type for the parsing primitives.
/// 
/// It contains the full contents of the cell that failed to parse, the name of the parser
/// used, as well as a generic `additional_context` field inside of an `Option`.
/// 
/// All of the parsing primitives return a `ValueError` that is unspecialised, as the
/// `additional_context` field is set to `None`. Thus, they will work with any specialised
/// `ValueError` type you create without any additional code required.
/// 
pub type ValueError(e) {
  ValueError(
    cell: String,
    path: List(String),
    reasons: List(Option(String)),
    additional_context: Option(e),
  )
}

/// Create your own custom primitive parser and make it also return a `ValueError`.
/// 
/// The function should return either `Ok(a)` where `a` is your desired data type, or
/// `Error(#(Option(String, b)))`, where `Option(String)` is appended to the `reasons`
/// field of the `ValueError` record, and `b` is an arbitrary data type that specializes
/// the `ValueError` type - so, you could just return `Nil`, or create your own,
/// custom Error type.
/// 
pub fn make_primitive(
  name: String,
  func: fn(String) -> Result(a, #(Option(String), b)),
) -> fn(String) -> Result(a, ValueError(b)) {
  fn(val: String) {
    val
    |> func()
    |> result.map_error(fn(err) {
      ValueError(val, [name], [err.0], Some(err.1))
    })
  }
}

/// Parse a `String` value as a base 10 integer.
/// 
pub fn integer(val: String) -> Result(Int, ValueError(_)) {
  integer_arbitrary_base(10)(val)
}

/// Parse a `String` value as a base 16 hexadecimal integer.
/// 
pub fn integer_hex(val: String) -> Result(Int, ValueError(_)) {
  integer_arbitrary_base(16)(val)
}

/// Parse a `String` value as a base 2 (binary) integer.
/// 
pub fn integer_binary(val: String) -> Result(Int, ValueError(_)) {
  integer_arbitrary_base(2)(val)
}

/// The `int.base_parse` Gleam standard library function used in this function works only
/// for bases greater than 1, and lower than 37. So anything from 2 to 36.
/// 
/// Therefore, if a base Int outside of these bounds is passed into this function, it will
/// panic before returning any value.
/// 
/// ### Note
/// If you are of the opinion that this behaviour should be different, you're welcome to
/// copy the function code and remove the panic, or create an Issue on the GitHub repository.
/// 
pub fn integer_arbitrary_base(
  base: Int,
) -> fn(String) -> Result(Int, ValueError(_)) {
  case base {
    b if b < 2 || b > 36 -> panic
    b -> fn(val: String) -> Result(Int, ValueError(_)) {
      case val {
        "" ->
          Error(ValueError(
            val,
            ["Integer base " <> int.to_string(b)],
            [Some("Cell was empty")],
            None,
          ))
        non_empty ->
          non_empty
          |> string.trim()
          |> int.base_parse(b)
          |> result.map_error(fn(_) {
            ValueError(
              val,
              ["Integer base " <> int.to_string(b)],
              [
                case string.contains(non_empty, ".") {
                  True -> Some("For floating point numbers, use parse.float")
                  False -> None
                },
              ],
              None,
            )
          })
      }
    }
  }
}

/// Primitive parser for a float value, along with a corresponding error message.
/// 
/// It supports values written like `10`, `.01`, `10.` - as long as a number could be
/// converted to a `Float`, it will be.
/// 
/// However, it does not support formats such as `1.0f` - only decimal digits and the
/// period (dot) are allowed, and only one dot.
/// 
pub fn float(val: String) -> Result(Float, ValueError(_)) {
  let parser_name = "Float"
  case val {
    "" -> Error(ValueError(val, [parser_name], [Some("Cell was empty")], None))
    non_empty -> {
      let trimmed = string.trim(non_empty)
      case string.split(trimmed, ".") {
        ["", decimals] -> Ok("0." <> decimals)
        [whole, ""] -> Ok(whole <> ".0")
        [whole, decimals] -> Ok(whole <> "." <> decimals)
        [singular] -> Ok(singular <> ".0")
        other ->
          Error(ValueError(
            val,
            [parser_name],
            [
              Some(
                "Found "
                <> other
                |> list.length()
                |> int.to_string()
                <> " dots in cell; Only 0 or 1 are allowed.",
              ),
            ],
            None,
          ))
      }
      |> result.try(fn(str) {
        float.parse(str)
        |> result.map_error(fn(_) {
          ValueError(non_empty, [parser_name], [None], None)
        })
      })
    }
  }
}

/// Curried function. If strict, only the words `true` and `false` will
/// successfully parse into a `Bool` value.
/// 
/// If false, other acronyms can also be successfully parsed.
/// 
/// ### Acceptable non-strict values for `True`
/// `true`, `truth`, `tru`, `t`, `yes`, `y`, `1`
/// 
/// ### Acceptable non-strict values for `False`
/// `false`, `fake`, `f`, `no`, `n`, `0`
/// 
pub fn bool(strict: Bool) -> fn(String) -> Result(Bool, ValueError(_)) {
  fn(val: String) {
    let cleaned = val |> string.trim() |> string.lowercase()
    case cleaned {
      "true" -> Ok(True)
      "false" -> Ok(False)
      "truth" | "tru" | "t" | "yes" | "y" | "1" if !strict -> Ok(True)
      "fake" | "f" | "no" | "n" | "0" if !strict -> Ok(False)
      _ ->
        Error(ValueError(
          val,
          [
            case strict {
              True -> "Strict"
              False -> "Relaxed"
            }
            <> " Bool",
          ],
          [None],
          None,
        ))
    }
  }
}

/// A cell parser that acts as a guard.
/// 
/// If the value of the cell equals the stated value, return `Ok(Nil)`;
/// otherwise, return `Error(ValueError)` explaining the problem.
/// 
/// I'm not certain it will be useful.
/// 
pub fn accept_only(
  value expected: String,
) -> fn(String) -> Result(Nil, ValueError(_)) {
  fn(val: String) {
    case expected == val {
      True -> Ok(Nil)
      False ->
        Error(ValueError(
          val,
          ["Accept Only"],
          [Some("Is not [" <> expected <> "]")],
          None,
        ))
    }
  }
}

/// Primitive parser for Strings. It never fails, just wraps the passed in cell in `Ok`.
/// 
/// It exists only because parsing Strings is definitely something people will use this
/// library to do, and if they were to use this module of parsing primitives, seeing a
/// random `parse.column(Ok)` might be confusing if one is not familiar with the specific
/// structure of the `Parser`.
/// 
pub fn string(val: String) -> Result(String, _) {
  Ok(val)
}

/// Primitive parser for a single character.
/// 
/// This uses the `string.length` function to check if the length of the cell (when trimmed
/// of whitespace) is equal to 1. If it's empty (length 0), an `Error` stating so is returned,
/// and likewise if it's anything above 1.
/// 
pub fn char(val: String) -> Result(String, ValueError(_)) {
  let cleaned = string.trim(val)
  case string.length(cleaned) {
    1 -> Ok(cleaned)
    0 -> Error(ValueError(val, ["Char"], [Some("Cell was empty")], None))
    _ -> Error(ValueError(val, ["Char"], [Some("Multiple characters")], None))
  }
}

/// Transform the parser's return value using the provided function.
/// 
/// If the parser fails, this does nothing; In essence, this is a thin wrapper around the
/// [`result.map`](https://gleam-stdlib.hexdocs.pm/gleam/result.html#map) function from
/// the Gleam standard library.
/// 
/// For functions that may fail (return a `Result`) use the `try` function.
/// 
pub fn map(
  parser: fn(String) -> Result(a, ValueError(e)),
  func: fn(a) -> b,
) -> fn(String) -> Result(b, ValueError(e)) {
  let parser_name = "Map"
  fn(val: String) {
    val
    |> parser()
    |> result.map_error(fn(err) {
      let ValueError(cell, path, reasons, context) = err
      ValueError(cell, [parser_name, ..path], [None, ..reasons], context)
    })
    |> result.map(func)
  }
}

/// Transform the parser's error value using the provided function.
/// 
/// If the parser succeeds, this does nothing; In essence, this is a thin wrapper around the
/// [`result.map_error`](https://gleam-stdlib.hexdocs.pm/gleam/result.html#map_error) function
/// from the Gleam standard library.
/// 
/// Useful if you want to use the parsing primitives but are not satisfied with the error messages.
/// 
pub fn map_error(
  parser: fn(String) -> Result(a, ValueError(e)),
  func: fn(e) -> d,
) -> fn(String) -> Result(a, ValueError(d)) {
  let parser_name = "Map error"
  fn(val: String) {
    val
    |> parser()
    |> result.map_error(fn(err) {
      let ValueError(cell, path, reasons, context) = err
      ValueError(
        cell,
        [parser_name, ..path],
        [None, ..reasons],
        context |> option.map(func),
      )
    })
  }
}

/// If the provided parser succeeds, check if it returns `None` when passed to the
/// predicate function.
/// 
/// If the function returns `None`, do nothing and pass the value along;
/// If it returns `Some(err)`, replace the value with `Error(err)`.
/// 
/// Can be used to guard against specific successfully parsed values that are nevertheless
/// incorrect for a reason other than cell structure.
/// 
/// If you need more granular control over the value and want to transform it somehow,
/// use the `try` function instead.
/// 
pub fn require_custom(
  parser: fn(String) -> Result(a, ValueError(e)),
  predicate: fn(a) -> Option(e),
) -> fn(String) -> Result(a, ValueError(e)) {
  let parser_name = "Require custom"
  fn(val: String) {
    val
    |> parser()
    |> result.map_error(fn(err) {
      let ValueError(cell, path, reasons, context) = err
      ValueError(cell, [parser_name, ..path], [None, ..reasons], context)
    })
    |> result.try(fn(v) {
      case predicate(v) {
        None -> Ok(v)
        Some(err) ->
          Error(ValueError(
            val,
            [parser_name],
            [Some("Didn't pass custom predicate")],
            Some(err),
          ))
      }
    })
  }
}

/// If the provided parser succeeds, check if it passes the check.
/// 
/// If the function returns `True`, do nothing and pass the value along;
/// If it returns `False`, replace the value with a generic `ValueError` message.
/// 
/// Can be used to guard against specific successfully parsed values that are nevertheless
/// incorrect for a reason other than cell structure.
/// 
/// If you need more granular control over the returned `Error` type, use the `try` function,
/// or the `require_custom` function instead.
/// 
pub fn require(
  parser: fn(String) -> Result(a, ValueError(e)),
  predicate: fn(a) -> Bool,
) -> fn(String) -> Result(a, ValueError(e)) {
  let parser_name = "Require"
  fn(val: String) {
    val
    |> parser()
    |> result.map_error(fn(err) {
      let ValueError(cell, path, reasons, context) = err
      ValueError(cell, [parser_name, ..path], [None, ..reasons], context)
    })
    |> result.try(fn(parsed_val) {
      case predicate(parsed_val) {
        True -> Ok(parsed_val)
        False ->
          Error(ValueError(
            val,
            [parser_name],
            [Some("Didn't pass predicate")],
            None,
          ))
      }
    })
  }
}

/// If the provided parser succeeds, use the function to try and perform some operation on
/// the value, which might fail.
/// 
/// Can be used to guard against specific successfully parsed values that are nevertheless
/// incorrect for a reason other than cell structure.
/// 
pub fn try(
  parser: fn(String) -> Result(a, ValueError(e)),
  func: fn(a) -> Result(b, ValueError(e)),
) -> fn(String) -> Result(b, ValueError(e)) {
  let parser_name = "Try"
  fn(val: String) {
    val
    |> parser()
    |> result.try(func)
    |> result.map_error(fn(err) {
      let ValueError(cell, path, reasons, additional_context) = err
      ValueError(
        cell,
        [parser_name, ..path],
        [None, ..reasons],
        additional_context,
      )
    })
  }
}

/// If the provided parser fails, use the function to read the error and perform
/// some operation on it.
/// 
/// Can be used to recover from failure.
/// 
pub fn try_recover(
  parser: fn(String) -> Result(a, ValueError(e1)),
  func: fn(e1) -> Result(a, ValueError(e2)),
) -> fn(String) -> Result(a, ValueError(e2)) {
  let parser_name = "Try recover"
  fn(val: String) {
    val
    |> parser()
    |> result.try_recover(fn(err) {
      let ValueError(cell, path, reasons, context) = err
      case option.map(context, func) {
        Some(Ok(val)) -> Ok(val)

        Some(Error(ValueError(cell, path, reasons, additional_context))) ->
          Error(ValueError(
            cell,
            [parser_name, ..path],
            [None, ..reasons],
            additional_context,
          ))

        None ->
          Error(ValueError(
            cell,
            [parser_name, ..path],
            [Some("Context not present"), ..reasons],
            None,
          ))
      }
    })
  }
}

/// If the provided parser fails, replace it with the provided new value.
/// 
/// Can be used to recover from failure.
/// 
pub fn or(
  parser: fn(String) -> Result(a, ValueError(e)),
  default value: Result(a, ValueError(e)),
) -> fn(String) -> Result(a, ValueError(e)) {
  let parser_name = "Or"
  fn(val: String) {
    val
    |> parser()
    |> result.map_error(fn(err) {
      let ValueError(cell, path, reasons, additional_context) = err
      ValueError(
        cell,
        [parser_name, ..path],
        [None, ..reasons],
        additional_context,
      )
    })
    |> result.or(value)
  }
}

/// This cell can be optional.
/// 
/// If the cell is empty, return `Ok(none)`.
/// If it's not, try the provided parser.
/// 
pub fn option(
  parser: fn(String) -> Result(a, ValueError(e)),
) -> fn(String) -> Result(Option(a), ValueError(e)) {
  let parser_name = "Optional"
  fn(val: String) {
    case val {
      "" -> Ok(None)
      non_empty ->
        non_empty
        |> parser()
        |> result.map(Some)
        |> result.map_error(fn(err) {
          let ValueError(cell, path, reasons, additional_context) = err
          ValueError(
            cell,
            [parser_name, ..path],
            [None, ..reasons],
            additional_context,
          )
        })
    }
  }
}

// let parser_name = "Map"
// fn(val: String) {
//   val
//   |> parser()
//   |> result.map_error(fn(err) {
//     let ValueError(cell, path, reasons, context) = err
//     ValueError(cell, [parser_name, ..path], [None, ..reasons], context)
//   })
//   |> result.map(func)
// }

/// Attempt to parse this cell using the provided parser.
/// 
/// If it succeeds, return `Some(a)`; if it doesn't, return `None`.
/// 
pub fn attempt(
  parser: fn(String) -> Result(a, _),
) -> fn(String) -> Result(Option(a), _) {
  fn(val: String) {
    case parser(val) {
      Ok(out) -> Ok(Some(out))
      Error(_) -> Ok(None)
    }
  }
}

/// Try to use the provided parsers in the specified order.
/// 
/// If one of them succeeds, the successfully parsed value is immediately returned.
/// If all of them fail, an error is returned.
/// 
pub fn one_of(
  parsers: List(fn(String) -> Result(a, _)),
) -> fn(String) -> Result(a, ValueError(_)) {
  let parser_name = "One Of"
  fn(val: String) {
    parsers
    |> list.find_map(fn(try) { try(val) })
    |> result.map_error(fn(_) {
      ValueError(val, [parser_name], [Some("No parsers succeeded")], None)
    })
  }
}

/// Using the given parser, try to parse a cell as an array.
/// 
/// The `delimiters` argument specifies the boundaries of the cell. It has the structure
/// `#(prefix, suffix)`. If the cell is not wrapped in them (excluding whitespace), an
/// `Error` will be emitted. If it is, then the contents (without delimiters) are separated
/// on the `separator`, then mapped over and parsed using the provided parser.
/// 
/// If all of the elements are successfully parsed, the resulting `List(a)` is returned.
/// 
/// If not, the first Error is wrapped in a broader Error that explains what went wrong.
/// 
/// ## Note
/// Nested lists are not in my scope of consideration right now, so they're not natively
/// supported. Most obviously, if you try and nest two lists which use the same separators,
/// the nested list will be split into cells when the top level list is being split.
/// Of course it could be solved, the same way I did for splitting CSV cells and rows, but
/// for now, it's beyond the scope of this project. Honestly, even these primitives are most
/// likely scope creep, so I won't polish them to perfection.
/// 
/// If you do want to work on them yourself, you're welcome to, and if you could create a PR
/// in the event you made something useful, I'd be delighted.
/// 
/// But for now, I'll be leaving these functions alone.
/// 
pub fn array(
  parser: fn(String) -> Result(a, ValueError(e)),
  delimiters: #(String, String),
  separator: String,
) -> fn(String) -> Result(List(a), ValueError(e)) {
  let parser_name = "Array"
  fn(cell: String) {
    let trimmed = string.trim(cell)
    case
      string.starts_with(trimmed, delimiters.0)
      && string.ends_with(trimmed, delimiters.1)
    {
      True ->
        Ok(
          trimmed
          |> string.remove_prefix(delimiters.0)
          |> string.remove_suffix(delimiters.1)
          |> string.split(on: separator),
        )
      False ->
        Error(ValueError(
          cell,
          [parser_name],
          [
            Some(
              "Wasn't wrapped in delimiters #("
              <> delimiters.0
              <> ", "
              <> delimiters.1
              <> ")",
            ),
          ],
          None,
        ))
    }
    |> result.try(fn(els) {
      els
      |> list.map(fn(el) { parser(el) })
      |> result.all()
      |> result.map_error(fn(err) {
        let ValueError(element, path, reasons, context) = err
        ValueError(
          cell,
          [parser_name, ..path],
          [
            Some(
              "Failed using parser "
              <> util.list_to_string(path, function.identity)
              <> " on ["
              <> element
              <> "]",
            ),
            ..reasons
          ],
          context,
        )
      })
    })
  }
}
