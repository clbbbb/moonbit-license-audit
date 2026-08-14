// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn trim_ascii(text : String) -> String {
  if text.length() == 0 {
    return text
  }
  let mut start = 0
  let mut seen = false
  for index, ch in text {
    if !ascii_space(ch) {
      start = index
      seen = true
      break
    }
  }
  if !seen {
    return ""
  }
  let mut end = text.length()
  for index, ch in text {
    if !ascii_space(ch) {
      end = index + 1
    }
  }
  text.unsafe_substring(start~, end~)
}

///|
pub fn ascii_space(ch : Char) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

///|
pub fn lower_ascii(text : String) -> String {
  let mut out = ""
  for _, ch in text {
    if ch.is_ascii_uppercase() {
      out = out + [ch.to_ascii_lowercase()]
    } else {
      out = out + [ch]
    }
  }
  out
}

///|
pub fn upper_ascii(text : String) -> String {
  let mut out = ""
  for _, ch in text {
    if ch.is_ascii_lowercase() {
      out = out + [ch.to_ascii_uppercase()]
    } else {
      out = out + [ch]
    }
  }
  out
}

///|
pub fn join_with(values : Array[String], sep : String) -> String {
  let mut out = ""
  for index = 0; index < values.length(); index = index + 1 {
    if index > 0 {
      out = out + sep
    }
    out = out + values[index]
  }
  out
}

///|
pub fn join_lines(values : Array[String]) -> String {
  join_with(values, "\n")
}

///|
pub fn contains_string(values : Array[String], value : String) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
pub fn unique_strings(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    if !contains_string(result, value) {
      result.push(value)
    }
  }
  result
}

///|
pub fn split_char(text : String, sep : Char) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  for index, ch in text {
    if ch == sep {
      parts.push(text.unsafe_substring(start~, end=index))
      start = index + 1
    }
  }
  parts.push(text.unsafe_substring(start~, end=text.length()))
  parts
}

///|
pub fn text_replace(text : String, from : String, to : String) -> String {
  if from == "" {
    return text
  }
  let mut out = ""
  let mut current = text
  while true {
    match current.find(from) {
      Some(index) => {
        out = out + current.unsafe_substring(start=0, end=index) + to
        current = current.unsafe_substring(
          start=index + from.length(),
          end=current.length(),
        )
        continue
      }
      None => {
        out = out + current
        break
      }
    }
  }
  out
}
