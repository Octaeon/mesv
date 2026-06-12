import gleam/option.{None, Some}
import mesv/format.{LeftAlignPad, TrimAll, TrimStart}
import mesv/format/encode
import mesv/stream

type Row =
  #(Int, Bool, String, Int)

pub fn default_normal_test() -> Nil {
  let formatted =
    format.init()
    |> format.column("    Index    ", Some(LeftAlignPad(8, "-")), fn(v: Row) {
      "0x" <> encode.integer_hex(v.0)
    })
    |> format.column("    Boolean   \n", None, fn(v: Row) {
      "    " <> encode.bool(v.1) <> "    "
    })
    |> format.column("    String   \n  ", None, fn(v: Row) {
      encode.string(v.2)
    })
    |> format.column(" <Binary> \n", Some(TrimStart), fn(v: Row) {
      "b" <> encode.integer_binary(v.3) <> "    "
    })
    |> format.set_default_whitespace(TrimAll)
    |> format.preprocess([])
    |> format.then_run(stream.from_list([#(16, True, "huh?", 0)]))
    |> format.then_join("\n")

  assert formatted
    == "Index---,Boolean,String,\"<Binary> \n\"\n0x10----,true,huh?,b0    "
    as "Formatting default parameters | Normal"
}
