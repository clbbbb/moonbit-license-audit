///|
pub struct SourceLicense {
  path : String
  expression : String
  found : Bool
  valid : Bool
  message : String
} derive(Debug, Eq)

///|
pub fn source_license(
  path : String,
  expression : String,
  found : Bool,
  valid : Bool,
  message : String,
) -> SourceLicense {
  { path, expression, found, valid, message }
}

///|
pub fn extract_spdx_expression(source : String) -> String? {
  match extract_spdx_expressions(source) {
    [first, ..] => Some(first)
    [] => None
  }
}

///|
pub fn extract_spdx_expressions(source : String) -> Array[String] {
  let expressions : Array[String] = []
  for line in split_char(source, '\n') {
    match spdx_expression_in_comment(line) {
      Some(expression) => expressions.push(expression)
      None => ()
    }
  }
  expressions
}

///|
pub fn spdx_expression_in_comment(line : String) -> String? {
  let marker = "SPDX-License-Identifier:"
  match comment_text(line) {
    Some(comment) =>
      match comment.find(marker) {
        Some(index) => {
          let raw = comment.unsafe_substring(
            start=index + marker.length(),
            end=comment.length(),
          )
          Some(clean_comment_tail(raw))
        }
        None => None
      }
    None => None
  }
}

///|
pub fn comment_text(line : String) -> String? {
  let trimmed = trim_ascii(line)
  if trimmed.has_prefix("//") {
    Some(trimmed.unsafe_substring(start=2, end=trimmed.length()))
  } else if trimmed.has_prefix("/*") {
    Some(trimmed.unsafe_substring(start=2, end=trimmed.length()))
  } else if trimmed.has_prefix("*") {
    Some(trimmed.unsafe_substring(start=1, end=trimmed.length()))
  } else {
    None
  }
}

///|
pub fn clean_comment_tail(text : String) -> String {
  let trimmed = trim_ascii(text)
  let without_block = text_replace(trimmed, "*/", "")
  trim_ascii(without_block)
}

///|
pub fn scan_source(path : String, source : String) -> SourceLicense {
  let expressions = extract_spdx_expressions(source)
  match expressions {
    [first, ..] => {
      let invalid = first_invalid_spdx_expression(expressions)
      let conflicting = spdx_expressions_conflict(expressions)
      let valid = invalid is None && !conflicting
      source_license(
        path,
        normalize(first),
        true,
        valid,
        if valid {
          "ok"
        } else if conflicting {
          "conflicting SPDX-License-Identifier values"
        } else {
          validation_report(option_or(invalid, first))
        },
      )
    }
    [] =>
      source_license(path, "", false, false, "missing SPDX-License-Identifier")
  }
}

///|
pub fn first_invalid_spdx_expression(expressions : Array[String]) -> String? {
  for expression in expressions {
    if !is_valid(expression) {
      return Some(expression)
    }
  }
  None
}

///|
pub fn spdx_expressions_conflict(expressions : Array[String]) -> Bool {
  let normalized : Array[String] = []
  for expression in expressions {
    if !is_valid(expression) {
      return false
    }
    let value = normalize(expression)
    if !contains_string(normalized, value) {
      normalized.push(value)
    }
  }
  normalized.length() > 1
}

///|
pub fn scan_report(path : String, source : String) -> String {
  let item = scan_source(path, source)
  if item.found && item.valid {
    item.path + ": ok " + item.expression
  } else {
    item.path + ": " + item.message
  }
}

///|
pub fn scan_sources(
  paths : Array[String],
  sources : Array[String],
) -> Array[SourceLicense] {
  let result : Array[SourceLicense] = []
  let limit = min_int(paths.length(), sources.length())
  for index = 0; index < limit; index = index + 1 {
    result.push(scan_source(paths[index], sources[index]))
  }
  result
}

///|
pub fn scan_sources_report(
  paths : Array[String],
  sources : Array[String],
) -> String {
  let rows : Array[String] = []
  for item in scan_sources(paths, sources) {
    if item.found && item.valid {
      rows.push(item.path + ": ok " + item.expression)
    } else {
      rows.push(item.path + ": " + item.message)
    }
  }
  join_lines(rows)
}

///|
pub fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub fn missing_spdx_count(
  paths : Array[String],
  sources : Array[String],
) -> Int {
  let mut count = 0
  for item in scan_sources(paths, sources) {
    if !item.found {
      count = count + 1
    }
  }
  count
}

///|
pub fn invalid_spdx_count(
  paths : Array[String],
  sources : Array[String],
) -> Int {
  let mut count = 0
  for item in scan_sources(paths, sources) {
    if item.found && !item.valid {
      count = count + 1
    }
  }
  count
}
