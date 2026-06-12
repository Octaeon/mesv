import mesv/format.{LeftAlignPad, RightAlignPad, TrimAll, TrimStart}
import mesv/format/encode

type Row =
  #(Int, Bool, String, Int)

pub fn default_normal_test() -> Nil {
  let formatted =
    format.init()
    |> format.column("    Index    ", fn(v: Row) {
      "0x" <> encode.integer_hex(v.0)
    })
    |> format.column_whitespace(LeftAlignPad(8, " "))
    |> format.column("    Boolean   \n", fn(v: Row) { v.1 |> encode.bool() })
    |> format.column_whitespace(RightAlignPad(8, " "))
    |> format.column("    String   \n  ", fn(v: Row) { v.2 |> encode.string() })
    |> format.column_whitespace(TrimAll)
    |> format.column(" <Binary> ", fn(v: Row) {
      "b" <> encode.integer_binary(v.3)
    })
    |> format.column_whitespace(TrimStart)
    |> format.run([])

  assert formatted == "Index   , Boolean,String,<Binary> "
    as "Formatting default parameters | Normal"
}
