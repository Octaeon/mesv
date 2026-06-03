//// A file containing various utility functions that don't exactly fit into any of the other modules.
//// 
//// They are purely for internal use - but since most of them are generic, there's nothing stopping you, as the end user,
//// from calling them in your own code.
//// 
//// However, beacause:
////  1. I doubt most people would find themselves in a situation where they need them
////  2. They are not particularly easy to understand
//// 
//// these functions are not considered part of the functionality provided by this library, and therefore
//// are not documented that well.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Internal helper function that traverses a list, calling the `merge` function on all consecutive elements.
/// 
/// ### Function Definition
/// ```gleam
/// list_merge_map(list: List(a), merge: fn(a, a) -> Option(a)) -> List(a)
/// ```
/// 
/// If the function returns `Some(a)`, then the two elements are replaced with the contents, and if it returns `None`,
/// the function advances to the next pair of elements.
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

/// Internal helper function to count how many **non-overlapping** occurences of the first argument are in the second argument.
/// 
/// If there are none, this function returns the length of the second argument.
/// 
/// ### Function Definition
/// ```gleam
/// count_occurences(of find: String, in string: String) -> Int
/// ```
/// 
pub fn count_occurences(of find: String, in in: String) -> Int {
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
