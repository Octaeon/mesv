//// A file containing various utility functions that don't exactly fit into any of the other modules.
//// 
//// They are purely for internal use - but since most of them are generic, there's nothing stopping you, as the end user, from calling them in your own code.
//// 
//// However, beacause:
////  1. I doubt most people would find themselves in a situation where they need them
////  2. They are not particularly easy to understand
//// 
//// these functions are not considered part of the functionality provided by this library, and therefore are not documented that well.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Internal helper function that traverses a list, calling the `merge` function on
/// all consecutive elements.
/// 
/// If the function returns `Some(a)`, then the two elements are replaced with the contents,
/// and if it returns `None`, the function advances to the next pair of elements.
/// 
pub fn list_merge_map(list: List(a), merge: fn(a, a) -> Option(a)) -> List(a) {
  list_merge_map_loop(list, merge, [])
}

fn list_merge_map_loop(
  list: List(a),
  merge: fn(a, a) -> Option(a),
  acc: List(a),
) -> List(a) {
  case list {
    [] -> list.reverse(acc)
    [last] -> list.reverse([last, ..acc])
    [first, second, ..rest] ->
      case merge(first, second) {
        Some(merged) -> list_merge_map_loop([merged, ..rest], merge, acc)
        None -> list_merge_map_loop([second, ..rest], merge, [first, ..acc])
      }
  }
}

/// Internal helper function to count how many **overlapping** occurences of the first argument
/// appear in the second argument.
/// 
/// If there are none, this function returns the length of the second argument.
/// 
pub fn count_overlapping(of find: String, in in: String) -> Int {
  case string.is_empty(find) {
    // If the string to search for is empty, assume the user is trying to find the length of the string they're searching
    True -> string.length(in)
    False ->
      recursive_count(
        in,
        fn(source: String) -> #(String, Int) {
          #(
            string.drop_start(source, 1),
            case string.slice(source, 0, string.length(find)) == find {
              True -> 1
              False -> 0
            },
          )
        },
        string.is_empty,
        0,
      )
  }
}

/// Internal helper function to count how many **non-overlapping** occurences of the first argument
/// appear in the second argument.
/// 
/// If there are none, this function returns the length of the second argument.
/// 
pub fn count_non_overlapping(of find: String, in in: String) -> Int {
  case string.is_empty(find) {
    // If the string to search for is empty, assume the user is trying to find the length of the string they're searching
    True -> string.length(in)
    False ->
      recursive_count(
        in,
        fn(source: String) -> #(String, Int) {
          let len = string.length(find)
          #(
            string.drop_start(source, len),
            case string.slice(source, 0, len) == find {
              True -> 1
              False -> 0
            },
          )
        },
        string.is_empty,
        0,
      )
  }
}

fn recursive_count(
  from: a,
  fun: fn(a) -> #(a, Int),
  exhausted: fn(a) -> Bool,
  acc: Int,
) -> Int {
  case exhausted(from) {
    True -> acc
    False -> {
      let #(next, add) = fun(from)
      recursive_count(next, fun, exhausted, acc + add)
    }
  }
}

/// Internal helper function for creating a function for 'unescaping' an element
/// (for each `rule`, replacing the second element in the tuple with the first).
/// 
/// Importantly, it does not `unwrap` the cell from escapers, just deduplicates them.
/// 
/// This function takes in a String that is guaranteed to be a value - that is,
/// it'seither unescaped, or it starts with an escaper and ends with an escaper.
/// 
/// It's a curried function because I like functional programming, and because it *should*
/// give some performance improvements if I create such a function before any looping
/// instead of constructing one for each iteration.
/// 
pub fn multi_replace(rules: List(#(String, String))) -> fn(String) -> String {
  fn(el: String) -> String {
    rules
    |> list.map(fn(rule: #(String, String)) -> fn(String) -> String {
      string.replace(each: rule.0, with: rule.1, in: _)
    })
    |> list.fold(el, fn(acc: String, rule: fn(String) -> String) -> String {
      rule(acc)
    })
  }
}

/// > **Caution!** This is not a part of the provided API, so a breaking change can
///   occur in every version change, without prior notice. Use with care.
/// 
/// Internal helper function for constructing a function that splits a `String`
/// on `separator`, as long as the `separator` is not between two `not_in`.
/// 
/// It is public because I created unit tests for it.
/// 
pub fn split_on_unescaped(
  separator el: String,
  not_in escaper: String,
) -> fn(String) -> List(String) {
  // Change done :)
  fn(to_split: String) -> List(String) {
    to_split
    // First split the string on the separator
    |> string.split(on: el)
    // Then traverse the List and merge any two Strings that don't form a cell together
    |> list_merge_map(fn(first: String, second: String) -> Option(String) {
      // If the first string contains an odd number of escaper Strings, merge the two
      case count_overlapping(of: escaper, in: first) % 2 == 1 {
        // I almost forgot to readd the separator when merging the strings.
        True -> Some(first <> el <> second)
        False -> None
      }
    })
  }
}
