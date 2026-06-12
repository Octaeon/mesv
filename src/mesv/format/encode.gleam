import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Format an `Int` into a `String` in an arbitrary base, as long as that base is more
/// than 1 and less than 37.
/// 
/// If the provided base is not within this range, this function will panic during
/// `Formatter` construction.
/// 
pub fn integer_arbitrary_base(base: Int) -> fn(Int) -> String {
  case base {
    // If the user passed in a base less than 2 or more than 36, this function will
    // return an Error, but since I don't want errors like this to possibly propagate,
    // the program will panic if that happens in the process of creating the formatter
    b if b < 2 || b > 36 -> panic
    b -> fn(num: Int) {
      case int.to_base_string(num, b) {
        Ok(str) -> str
        Error(_) -> panic
      }
    }
  }
}

/// Format an `Int` into a `String` in base 10 (decimal).
/// 
pub fn integer(num: Int) -> String {
  int.to_string(num)
}

/// Format an `Int` into a `String` in base 16 (hexadecimal).
/// 
pub fn integer_hex(num: Int) -> String {
  int.to_base16(num)
}

/// Format an `Int` into a `String` in base 2 (binary).
/// 
pub fn integer_binary(num: Int) -> String {
  int.to_base2(num)
}

/// Format a `Float` into a `String` in base 10 (decimal).
/// 
pub fn float(num: Float) -> String {
  float.to_string(num)
}

/// Format a `Bool` into a `String`.
/// 
/// ## Example
/// ```gleam
/// assert primitive.bool(True) == "true"
/// assert primitive.bool(False) == "false"
/// ```
/// 
pub fn bool(val: Bool) -> String {
  case val {
    True -> "true"
    False -> "false"
  }
}

/// Format a `String` into a `String`.
/// 
/// It exists only because when using the column based builder, seeing
/// ```gleam
/// format.column("Name", primitive.string)
/// ```
/// is easier to understand than
/// ```gleam
/// format.column("Name", function.identity)
/// ```
/// 
pub fn string(val: String) -> String {
  val
}

/// Transform a formatter of type `a` into one of type `Option(a)`.
/// 
/// If the value being formatted is `Some`, then the provided formatter is used.
/// If it's `None`, then an empty `String` is returned.
/// 
/// ## Examples
/// ```gleam
/// assert option(bool)(Some(True))  == "true"
/// assert option(bool)(Some(False)) == "false"
/// assert option(bool)(None) == ""
/// assert option(bool)(None) == ""
/// ```
/// 
pub fn option(formatter: fn(a) -> String) -> fn(Option(a)) -> String {
  fn(maybe_val: Option(a)) -> String {
    case maybe_val {
      Some(val) -> formatter(val)
      None -> ""
    }
  }
}

/// Transform a formatter of type `a` into one of type `Option(a)`.
/// 
/// If the value being formatted is `Some`, then the provided formatter is used.
/// If it's `None`, then the provided default value is returned.
/// 
/// ## Examples
/// ```gleam
/// assert default(bool, "None")(Some(True))  == "true"
/// assert default(bool, "None")(Some(False)) == "false"
/// assert default(bool, "None")(None) == "None"
/// assert default(bool, "None")(None) == "None"
/// ```
/// 
pub fn default(
  formatter: fn(a) -> String,
  default: String,
) -> fn(Option(a)) -> String {
  fn(maybe_val: Option(a)) -> String {
    case maybe_val {
      Some(val) -> formatter(val)
      None -> default
    }
  }
}

/// Transform the provided formatter of the type `a` into a formatter for the type `List(a)`,
/// where each value is separated by `separator` and the entire cell is wrapped in `delimiters`.
/// 
/// ## Note
/// There is no mechanism for ensuring the elements of the array don't contain any illegal
/// values - that is, the separator.
/// 
/// Thus, it's possible to create a formatter and parser with the same delimiters, separators,
/// and whose primitive parsers are lossless in a round trip (ie, `parse(format(val)) == val`
/// for all possible val), but which do not hold that same property.
/// 
/// It is certainly possible to achieve, but not a priority for me.
/// 
pub fn array(
  formatter: fn(a) -> String,
  delimiters: #(String, String),
  separator: String,
) -> fn(List(a)) -> String {
  fn(values: List(a)) -> String {
    let arr = values |> list.map(formatter) |> string.join(separator)
    delimiters.0 <> arr <> delimiters.1
  }
}
