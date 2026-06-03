import gleeunit

pub type RowData {
  RowData(name: String, age: Int, comment: String)
}

pub fn normal_data() -> List(RowData) {
  [
    RowData("Alex", 23, "This is a pretty cool library"),
    RowData("Bartholemew", 24, "Yeah I agree"),
  ]
}

pub fn column_separator_data(column_separator: String) -> List(RowData) {
  [
    RowData("Alex", 23, "This is a pretty good library, don't you think?"),
    RowData(
      "Bartholemew",
      24,
      "Yeah, it's pretty good, but are you sure it can handle escaping separators? Try "
        <> column_separator
        <> " this. heh",
    ),
  ]
}

pub fn row_separator_data(row_separator: String) -> List(RowData) {
  [
    RowData("Alex", 23, "It should be able to, right?"),
    RowData(
      "Bartholemew",
      24,
      "Maybe column separators,"
        <> row_separator
        <> "but what about row separators?",
    ),
  ]
}

pub fn escaper_data(escaper: String) -> List(RowData) {
  [
    RowData("Bartholemew", 24, "Huh, it worked. Now only escapers remain."),
    RowData("Alex", 23, "What are escapers?"),
    RowData(
      "Bartholemew",
      24,
      "They're what wrap a value if it contains reserved elements. Right now, it's "
        <> escaper,
    ),
  ]
}

/// Main function that acts as the entrypoint for the testing library `gleeunit`.
/// 
/// By calling `gleeunit.main()`, it will scan all of the files in the root `test` folder,
/// and call all functions that end in `_test`.
/// 
/// These test functions should return `Nil`, and any function that panics is considered failed.
pub fn main() -> Nil {
  gleeunit.main()
}
