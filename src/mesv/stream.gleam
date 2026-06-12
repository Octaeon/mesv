import gleam/list
import gleam/option.{type Option, None, Some}

// ==== Public Types ====

pub type Step(a) {
  Next(Stream(a), a)
  Done
}

pub type Stream(a) {
  Stream(fn() -> Step(a))
}

// ==== Public API ====

// => Constructors

/// Create an empty `Stream` that always returns `Done` for the next step.
/// 
pub fn empty() -> Stream(a) {
  Stream(fn() { Done })
}

/// Create a `Stream` with a singular element that it returns once, then finishes.
/// 
pub fn single(el: a) -> Stream(a) {
  Stream(fn() { Next(empty(), el) })
}

/// Create a `Stream` from a `List` of elements, which it will output in order, after which
/// it will be finished.
/// 
pub fn from_list(from: List(a)) -> Stream(a) {
  Stream(fn() {
    case from {
      [] -> Done
      [head, ..rest] -> Next(from_list(rest), head)
    }
  })
}

/// Create a `Stream` from a provided iterating function and an initial value, which will forever
/// return the next element as obtained by calling the iterating function on the current element.
/// 
/// The initial value provided is the first element of the returned `Stream`.
/// 
pub fn from_iterator(iter: fn(a) -> a, initial: a) -> Stream(a) {
  Stream(fn() { Next(from_iterator(iter, iter(initial)), initial) })
}

/// Create a `Stream` from a given `source`, as well as a function that takes `chunk`s out
/// of the source and returns it, diminished in some way (or not).
/// 
/// The `source` thus provided, cannot be extracted from within the resulting `Stream` without
/// having to undo the `chunk` function.
/// 
/// Due to the type signature of this function, the `source` and output types can be different,
/// making it possible to directly transform the source somehow.
/// For example, if you have a producer of a byte stream, the chunk function can at the same
/// time request more, cut it off at appropriate points, and parse it.
/// 
/// Keep in mind however, that blocking operations called from within the `chunk` function will
/// block the process from which the `Stream` was consumed to get the next value; however, the
/// `Stream` has no idea whether the provided function is blocking or not. As such, if you
/// create a blocking `Stream`, it's up to you as the user to remember that it is blocking.
/// 
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

/// Create an infinite `Stream` only producing this single value.
/// 
pub fn repeat(element: a) -> Stream(a) {
  Stream(fn() { Next(repeat(element), element) })
}

/// Transform a finite `Stream` into an infinite one by making it loop forever.
/// 
/// It can also be used with infinite `Stream`s, but since this function works by waiting
/// until the stream is finished then replacing the `Done` value with another instance of
/// that `Stream`, using it on infinite `Stream`s is pointless, since they never return `Done`.
/// 
pub fn repeat_stream(stream: Stream(a)) -> Result(Stream(a), Nil) {
  case next(stream) {
    Next(_, _) -> Ok(repeat_loop(stream, empty()))
    // If the input stream returns Done, then trying to call `repeat_loop` would create a `Stream`
    // that can never return the next value
    Done -> Error(Nil)
  }
}

fn repeat_loop(repeat: Stream(a), acc: Stream(a)) -> Stream(a) {
  Stream(fn() {
    case next(acc) {
      Next(stream, value) -> Next(repeat_loop(repeat, stream), value)
      Done -> next(repeat_loop(repeat, repeat))
    }
  })
}

// => Destructors (Getters)

/// Consume the provided `Stream` and collect all of the values into a `List`.
/// 
/// ## Note
/// As this function attempts to eagerly evaluate all of the elements until it encounters
/// the `Done` next step, if called on an infinite `Stream`, it will never terminate.
/// 
pub fn to_list(stream: Stream(a)) -> List(a) {
  to_list_loop(stream, [])
}

fn to_list_loop(stream: Stream(a), acc: List(a)) -> List(a) {
  case next(stream) {
    Next(stream, value) -> to_list_loop(stream, [value, ..acc])
    Done -> list.reverse(acc)
  }
}

/// Consume the provided `Stream` and collect `count` number of values into a `List`.
/// 
/// Since this function has a built in limit, as long as all of the elements in the
/// `Stream` can be evaluated and terminate, it will also terminate, even if the
/// `Stream` is infinite.
/// 
/// Basically, using this function protects you against the infinite length of the `Stream`,
/// but cannot protect you against potentially infinite requirements of the internal
/// function of the `Stream`.
/// 
pub fn take(stream: Stream(a), count: Int) -> List(a) {
  take_loop(stream, count, [])
}

fn take_loop(stream: Stream(a), count: Int, acc: List(a)) -> List(a) {
  case count, next(stream) {
    c, Next(stream, value) if c > 0 ->
      take_loop(stream, count - 1, [value, ..acc])
    _, _ -> list.reverse(acc)
    // If c is less than or equal to zero, or the `Stream` ended, return the accumulator
  }
}

/// Consume all of the elements of a `Stream` and fold them into a single value,
/// using the provided function and initial accumulator.
/// 
/// ## Note
/// Since this function tries to collect all of the elements of the input `Stream`,
/// if the `Stream` is infinite, then it will never terminate.
/// 
pub fn foldl(stream: Stream(a), fun: fn(a, b) -> b, acc: b) -> b {
  case next(stream) {
    Next(stream, value) -> foldl(stream, fun, fun(value, acc))
    Done -> acc
  }
}

/// Consume all of the elements of a `Stream` and join them into a single value,
/// using the provided function.
/// 
/// If the stream is empty, return `Error(Nil)`, and if there's only a single value, return that.
/// Only if there are two or more elements is the function called.
/// 
/// I made this function to imitate the output of the `string.join` function, but since unlike
/// `String`s, this function works for an arbitrary element, I can't just return an empty string
/// like `string.join` does. So, under the hood, this function just gets the next step of the
/// `Stream` once, and then just calls [`foldl`](stream.html#foldl), with the initial accumulator
/// being the first element of the `Stream`.
/// 
/// ## Note
/// Since this function tries to collect all of the elements of the input `Stream`,
/// if the `Stream` is infinite, then it will never terminate.
/// 
pub fn join(stream: Stream(a), fun: fn(a, a) -> a) -> Result(a, Nil) {
  case next(stream) {
    Next(stream, value) -> Ok(foldl(stream, fun, value))
    Done -> Error(Nil)
  }
}

/// Collect the values inside of the `Stream` into the List until an element evaluates
/// `True` when passed into the `stop` argument.
/// 
/// When an element evaluates `True`, the function ends, and returns the List containing
/// all of the previous elements **without** that one, and the `Stream` which **does**
/// contain that element.
/// 
/// ## Note
/// This is done by recursively traversing the `Stream` output until we encounter an element
/// that evaluates to `True` when passed to the `stop` function, and then prepending that
/// element to the `Stream`.
/// 
/// As such, if your `Stream` is created from a function that executes some side-effect to
/// obtain the next value, if you use this function, the very next iteration of this `Stream`
/// will not execute that operation, since it has the output of that function stored inside
/// of it.
/// 
/// The simplest example is if you had a `Stream` that returned the system time whenever
/// you called it. Then, if you for some reason used this function, the very next element
/// you'd get from this `Stream` would be the time in the past, when the function was
/// evaluated inside of this function.
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

/// Get the next value from the `Stream`.
/// 
/// ## Note
/// If the `Stream` was constructed from a function, that function is called to produce that value,
/// so if that function never terminates, then the `next` function will also never terminate.
/// 
pub fn next(stream: Stream(a)) -> Step(a) {
  let Stream(step) = stream
  step()
}

// => Transformations

/// Drop `count` elements from the beginning of the `Stream`.
/// 
/// If there are no elements left (the `next` function returned `Done`),
/// an empty `Stream` is returned.
/// 
pub fn drop(stream: Stream(a), count: Int) -> Stream(a) {
  case count {
    0 -> stream
    _ -> {
      case next(stream) {
        Next(stream, _) -> drop(stream, count - 1)
        Done -> empty()
      }
    }
  }
}

/// Transform the provided `Stream` using the given function.
/// 
/// This is done lazily - a new `Stream` is constructed, whose internal function just
/// gets the next `Step` from the old `Stream`, transforms the provided value using the
/// function, and constructs a new `Stream` by calling itself on the one that was
/// returned inside of the `Step` type.
/// 
pub fn map(stream: Stream(a), fun: fn(a) -> b) -> Stream(b) {
  Stream(fn() {
    case next(stream) {
      Next(stream, value) -> Next(map(stream, fun), fun(value))
      Done -> Done
    }
  })
}

/// Combines two `Stream`s into another using the given function.
/// 
/// This is done lazily - a new `Stream` is constructed, whose internal function just
/// gets the next `Step` from the old `Stream`s, and if both return a `Next` variant,
/// return a `Next` step by calling itself recursively on the new streams and call the
/// function on the two values.
/// 
/// Thus, if either of the `Stream`s end, the resulting `Stream` ends - in short, the
/// length of the resulting `Stream` is the minimum of the length of the two input `Stream`s.
/// 
pub fn map2(
  first: Stream(a),
  second: Stream(b),
  fun: fn(a, b) -> c,
) -> Stream(c) {
  Stream(fn() {
    case next(first), next(second) {
      Next(next_first, val_first), Next(next_second, val_second) ->
        Next(map2(next_first, next_second, fun), fun(val_first, val_second))
      _, _ -> Done
    }
  })
}

/// Transform a `Stream` to only retain values that match the predicate.
/// 
/// ## Note
/// This function works by creating a new `Stream`, which for every element that is
/// requested, requests an element from the provided `Stream`.
/// If the returned element passes the function, then it stops there and returns itself,
/// but if it does not, then it recursively calls itself until the element passes.
/// 
/// As such, if a `Stream` created using this function were to be based on an infinite
/// `Stream` and the values that pass were extremely rare, then calling `next()` on such
/// a `Stream` would take a long time.
/// Furthermore, if no elements in the input infinite `Stream` were to pass the predicate,
/// then calling `next()` on such a `Stream` will never return.
/// 
pub fn filter(stream: Stream(a), predicate: fn(a) -> Bool) -> Stream(a) {
  Stream(fn() {
    case next(stream) {
      Next(next_stream, value) -> {
        case predicate(value) {
          True -> Next(filter(next_stream, predicate), value)
          False -> next(filter(next_stream, predicate))
        }
      }
      Done -> Done
    }
  })
}

/// Transform a `Stream` to only retain values that are returned in an `Ok` variant of the
/// `Result` monad.
/// 
/// Basically equivalent to the composition of `filter` and `map`, just a bit more optimized.
/// 
/// ## Note
/// This function works by creating a new `Stream`, which for every element that is
/// requested, requests an element from the provided `Stream`.
/// If the returned element passes the function, then it stops there and returns itself,
/// but if it does not, then it recursively calls itself until the element passes.
/// 
/// As such, if a `Stream` created using this function were to be based on an infinite
/// `Stream` and the values that pass were extremely rare, then calling `next()` on such
/// a `Stream` would take a long time.
/// Furthermore, if no elements in the input infinite `Stream` were to pass the predicate,
/// then calling `next()` on such a `Stream` will never return.
/// 
pub fn filter_map(
  stream: Stream(a),
  predicate: fn(a) -> Result(b, e),
) -> Stream(b) {
  Stream(fn() {
    case next(stream) {
      Next(next_stream, value) -> {
        case predicate(value) {
          Ok(new_val) -> Next(filter_map(next_stream, predicate), new_val)
          Error(_) -> next(filter_map(next_stream, predicate))
        }
      }
      Done -> Done
    }
  })
}

/// Consume the provided `Stream` and execute a function on each element, eagerly consuming them.
/// 
/// Use to execute side-effects based on the values in the `Stream` using functions that
/// cannot fail, when you don't care about the consumed values on their own afterwards.
/// 
/// ## Note
/// If the provided `Stream` is infinite, this function will never return.
/// 
pub fn each(stream: Stream(a), evaluate fun: fn(a) -> Nil) -> Nil {
  case next(stream) {
    Next(stream, value) -> {
      fun(value)
      each(stream, fun)
    }
    Done -> Nil
  }
}

/// Add the provided element to the *start* of the Stream (ie, it will be the next element shown)
/// 
pub fn prepend(stream: Stream(a), element: a) -> Stream(a) {
  Stream(fn() { Next(stream, element) })
}

/// If the provided element is `Some`, add the provided element to the *start* of the Stream
/// (ie, it will be the next element shown). Otherwise, return the `Stream` unchanged.
/// 
pub fn maybe_prepend(stream: Stream(a), maybe_element: Option(a)) -> Stream(a) {
  case maybe_element {
    Some(el) -> prepend(stream, el)
    None -> stream
  }
}

/// Add the provided element to the *end* of the Stream (ie, it will be the last element shown)
/// 
/// ## Note
/// If the stream is infinite, this element will never be returned, since this function only
/// waits until the stream returns `Done`, and then replaces that `Done` with `Next(empty(),
/// element)`. So if the `Stream` never returns done, that element will never be returned.
/// 
pub fn append(stream: Stream(a), element: a) -> Stream(a) {
  Stream(fn() {
    case next(stream) {
      Next(stream, value) -> Next(append(stream, element), value)
      Done -> Next(empty(), element)
    }
  })
}

/// Concatonate two `Stream`s together.
/// 
/// ## Note
/// If the first `Stream` is infinite, then the second `Stream` will never appear.
/// 
pub fn concat(first: Stream(a), second: Stream(a)) -> Stream(a) {
  Stream(fn() {
    case next(first) {
      Next(stream, value) -> Next(concat(stream, second), value)
      Done -> next(second)
    }
  })
}

pub fn wrap(stream: Stream(a), in element: a) -> Stream(a) {
  stream
  |> append(element)
  |> prepend(element)
}
