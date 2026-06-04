import gleam/list
import mesv/util

pub fn split_on_unescaped_base_test() -> Nil {
  let in = "should,split,on,these,commas"
  assert util.split_on_unescaped(separator: ",", not_in: "\"")(in)
    == ["should", "split", "on", "these", "commas"]
    as "Split on unescaped | Base case equivalent to string.split"
}

pub fn split_on_unescaped_one_escaped_test() -> Nil {
  let in = "should,split,on,these,commas,but,not,\"on this,one\",continued"
  assert util.split_on_unescaped(separator: ",", not_in: "\"")(in)
    == [
      "should",
      "split",
      "on",
      "these",
      "commas",
      "but",
      "not",
      "\"on this,one\"",
      "continued",
    ]
    as "Split on unescaped | Strings starting with escapers"
}

pub fn split_on_unescaped_nested_escaper_test() -> Nil {
  let in = "now,for,rows\nthese,should,work\nand,\"this\none\",too"
  assert util.split_on_unescaped(separator: "\n", not_in: "\"")(in)
    == ["now,for,rows", "these,should,work", "and,\"this\none\",too"]
    as "Split on unescaped | Escaper in the middle"
}

pub fn split_on_unescaped_nested_multiple_escaper_test() -> Nil {
  let in =
    "now,for,rows\nthese,should,work\nand,\"this\none, with \"\"more escapers\"\"\",too"
  assert util.split_on_unescaped(separator: "\n", not_in: "\"")(in)
    == [
      "now,for,rows",
      "these,should,work",
      "and,\"this\none, with \"\"more escapers\"\"\",too",
    ]
    as "Split on unescaped | Multiple escapers in the middle"
}

pub fn count_occurences_empty_string_test() -> Nil {
  assert util.count_overlapping(of: "\"", in: "") == 0
    as "Count Occurences | Empty string search"
}

pub fn count_occurences_empty_search_test() -> Nil {
  // Due to how I implemented this function, I decided that when counting the number of occurences of
  // empty strings in a string `a`, the output will be the length of `a`.
  assert util.count_overlapping(of: "", in: "What is it even searching for?")
    == 30
    as "Count Occurences | Search for empty string"
}

pub fn count_occurences_none_test() -> Nil {
  assert util.count_overlapping(of: ",", in: "and this") == 0
    as "Count Occurences | Zero present"
}

pub fn count_occurences_basic_test() -> Nil {
  assert util.count_overlapping(of: ",", in: "and, this") == 1
    as "Count Occurences | Basic case"
}

pub fn count_occurences_invisible_characters_test() -> Nil {
  assert util.count_overlapping(
      of: "\n",
      in: "basically\nequivalent\nto\ncounting\nhow many\nlines\nthere are",
    )
    == 6
    as "Count Occurences | Invisible characters"
}

pub fn count_occurences_list_test() -> Nil {
  let data = [
    #("whatever", "e", 2),
    #("maybe count \"doublequotes\"", "\"", 2),
    #(
      "\"OH NO, I FORGOT TO \"\"**ESCAPE**\"\" THE LAST TEST CASE!!!!\"",
      "\"",
      6,
    ),
    #("I'm running out of ideas...", " ", 4),
  ]
  assert list.map(data, fn(a) { util.count_overlapping(of: a.1, in: a.0) })
    == list.map(data, fn(a) { a.2 })
    as "Count Occurences | List of tests"
}

pub fn count_occurences_word_test() -> Nil {
  let data =
    "I want to count the number of multi-character strings in this sentence, to check if my function works for finding Strings that are more than a single character.
    to do this, I will need to use a sliding window instead of consuming the input one character by one character"
  assert util.count_overlapping(of: "to", in: data) == 4
    as "Count Occurences | Count occurences of multi-character substrings"
}
