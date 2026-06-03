import gleeunit

/// Main function that acts as the entrypoint for the testing library `gleeunit`.
/// 
/// By calling `gleeunit.main()`, it will scan all of the files in the root `test` folder,
/// and call all functions that end in `_test`.
/// 
/// These test functions should return `Nil`, and any function that panics is considered failed.
pub fn main() -> Nil {
  gleeunit.main()
}
