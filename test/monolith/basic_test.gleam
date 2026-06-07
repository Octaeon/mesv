import gleam/int
import gleam/pair
import mesv

pub fn simple_test() -> Nil {
  let builder =
    mesv.start({
      use str: String <- mesv.parsed
      use i: Int <- mesv.parsed

      #(str, i)
    })
    |> mesv.column(mesv.Mapping(
      get_string(_, 0),
      encode: fn(a) { a },
      decode: Ok,
    ))
    |> mesv.column(mesv.Mapping(
      pair.second,
      encode: int.to_string,
      decode: int.parse,
    ))

  assert 1 == { 0 + 1 }
}

fn get_string(from: fn(a) -> #(String, a), a1: a) -> String {
  case from {
    a -> todo
  }
  from(a1).0
}
