```
file         = [META *(key-value) META] [header] record *(NL record) [NL]
key-value    = meta-field COLON meta-field NL
meta-field   = (escaped-meta / plain-meta)
header       = name  *(COMMA name) NL
record       = field *(COMMA field)
name         = field
field        = (escaped-csv / plain-csv)
escaped-csv  = DQUOTE *(CSV-TEXT / COMMA / NL / 2DQUOTE) DQUOTE
escaped-meta = DQUOTE *(META-TEXT / HYPHEN / COLON / NL / 2DQUOTE) DQUOTE
plain-meta   = *META-TEXT
plain-csv    = *CSV-TEXT
META         = 3HYPHEN NL
NL           = (CRLF / CR / LF)
HYPHEN       = %x2D
COMMA        = %x2C
COLON        = %x3A
META-TEXT    = %x20-21 / %x23-2C / %x2E-39 / %x3B-7E
CSV-TEXT     = %x20-21 / %x23-2B / %x2D-7E
```

Using the [ABNF](https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form) grammar and based on the [CSV format specification](https://www.ietf.org/rfc/rfc4180.txt), I designed the above grammar for the files that are parsed by `mesv`.

In short, it describes that the contents of a `meta-field` must be escaped if they contain the `COLON` or `HYPHEN` characters, but not `COMMA` character - which can, of course be changed in the `Parser` building process.

## CSV Parity
MESV is almost a superset of the CSV format, if not for the fact that correct CSV could be incorrect MESV.

To illustrate, I will showcase one such file:
```
illegal:f:le
```
In a CSV grammar, this would be a structure like:
```
[:file [:record [:field [:non-escaped "illegal:f:le" ]]]]
```

So far so good.

But, if this line were wrapped in the `META` rule:
```
---
illegal:f:le
---
```

This is a perfectly fine CSV file, with three rows containing one element.

In Gleam, that would be:
```gleam
[ String("---")
, String("illegal:f:le")
, String("---")
]
```

However, if parsed with MESV, it would be a parsing error, as the `key-value` rule expects `meta-field` `:` `meta-field` `\n` - and the second `meta-field` is not escaped (wrapped in `"`), so it does not follow the specification of MESV.

## Customization
As stated above, it's possible to customize the specific values of the basic rules - that is, `DQUOTE`, `COMMA`, `COLON`, `HYPHEN` - and they will be automatically excluded from `META-TEXT` and `CSV-TEXT`.

Furthermore, if the user wants to, they can always skip the `parse.preprocess` function and set `expected_headers` to `Empty`.

Thus, it's possible to use `mesv` to parse and format normal CSV files in any given use case.

However, it's important to note that these two cannot be done at the same time - given a single `String` without any other accompanying data, it's impossible to tell whether that `String` is a MESV format or a CSV format, as some `Strings` parse successfully in both.

### Example
```
---
columns:String
---
name
Anthony
```

In CSV, this would parse to:
```gleam
[ "---"
, "columns:String"
, "---"
, "name"
, "Anthony"
]
```

In MESV, this would parse to:
```gleam
#(
  [#("columns", "String")] // metadata list
  [ "name"                 // List of parsed Strings
  , "Anthony"
  ]
)
```

Ultimately, it's up to the user to decide how they want to interpret a given input file.