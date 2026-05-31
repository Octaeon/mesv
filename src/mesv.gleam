//// A CSV parsing library that strongly enforces Data Integrity, allows for creation of both a formatter (`fn(data) -> String`) and parser (`fn(String) -> data`) from the same data type, and allows the user to add Frontmatter metadata to CSV files

import gleam/io

pub fn main() -> Nil {
  io.println("Hello from mesv!")
}
