import gleam/list

pub type Step(a) {
  Next(Stream(a), a)
  Done
}

pub type Stream(a) {
  Stream(fn() -> Step(a))
}

pub fn empty() -> Stream(a) {
  Stream(fn() { Done })
}

pub fn next(stream: Stream(a)) -> Step(a) {
  let Stream(step) = stream
  step()
}

pub fn drop(stream: Stream(a), count: Int) -> Stream(a) {
  case count {
    0 -> stream
    _ -> {
      let Stream(step) = stream

      case step() {
        Next(stream, _) -> drop(stream, count - 1)
        Done -> empty()
      }
    }
  }
}

pub fn from_list(from: List(a)) -> Stream(a) {
  Stream(fn() {
    case from {
      [] -> Done
      [head, ..rest] -> Next(from_list(rest), head)
    }
  })
}

pub fn from_function(iter: fn(a) -> a, initial: a) -> Stream(a) {
  Stream(fn() {
    let val = iter(initial)
    Next(from_function(iter, val), val)
  })
}

pub fn from_divider(
  source: a,
  chunk: fn(a) -> Result(#(a, b), b),
) -> Stream(b) {
  Stream(fn() {
    case chunk(source) {
      Ok(#(source, value)) -> Next(from_divider(source, chunk), value)
      Error(last_value) -> Next(empty(), last_value)
    }
  })
}

pub fn map(stream: Stream(a), func: fn(a) -> b) -> Stream(b) {
  let Stream(step) = stream

  Stream(fn() {
    case step() {
      Next(stream, value) -> Next(map(stream, func), func(value))
      Done -> Done
    }
  })
}

pub fn filter(stream: Stream(a), predicate: fn(a) -> Bool) -> Stream(a) {
  let Stream(step) = stream

  Stream(fn() { filter_loop(step, predicate) })
}

fn filter_loop(step: fn() -> Step(a), predicate: fn(a) -> Bool) -> Step(a) {
  case step() {
    Next(Stream(step), value) ->
      case predicate(value) {
        True -> Next(Stream(step), value)
        False -> filter_loop(step, predicate)
      }
    Done -> Done
  }
}

pub fn each(stream: Stream(a), evaluate fun: fn(a) -> Nil) -> Nil {
  let Stream(step) = stream

  case step() {
    Next(stream, value) -> {
      fun(value)
      each(stream, fun)
    }
    Done -> Nil
  }
}

pub fn to_list(stream: Stream(a)) -> List(a) {
  to_list_loop(stream, [])
}

fn to_list_loop(stream: Stream(a), acc: List(a)) -> List(a) {
  let Stream(step) = stream

  case step() {
    Next(stream, value) -> to_list_loop(stream, [value, ..acc])
    Done -> list.reverse(acc)
  }
}

/// Collect the values inside of the `Stream` into the List until an element returns `True` when tested with the `stop` argument.
/// 
/// When an element returns `True`, the function ends, and returns the List containing all of the previous elements **without** that one, and the `Stream` which **does** contain that element.
/// 
pub fn collect_until(
  stream: Stream(a),
  stop: fn(a) -> Bool,
) -> #(Stream(a), List(a)) {
  collect_until_loop(stream, stop, [])
}

fn collect_until_loop(
  stream: Stream(a),
  stop: fn(a) -> Bool,
  acc: List(a),
) -> #(Stream(a), List(a)) {
  case next(stream) {
    Next(next, val) ->
      case stop(val) {
        True -> #(prepend(next, val), list.reverse(acc))
        False -> collect_until_loop(next, stop, [val, ..acc])
      }
    Done -> #(empty(), list.reverse(acc))
  }
}

pub fn prepend(stream: Stream(a), element: a) -> Stream(a) {
  Stream(fn() { Next(stream, element) })
}

pub fn foldl(stream: Stream(a), fun: fn(a, b) -> b, acc: b) -> b {
  let Stream(step) = stream

  case step() {
    Next(stream, value) -> foldl(stream, fun, fun(value, acc))
    Done -> acc
  }
}
