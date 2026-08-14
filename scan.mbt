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
  let marker = "SPDX-License-Identifier:"
  for line in split_char(source, '\n') {
    match line.find(marker) {
      Some(index) => {
        let raw = line.unsafe_substring(
          start=index + marker.length(),
          end=line.length(),
        )
        return Some(clean_comment_tail(raw))
      }
      None => ()
    }
  }
  None
}

///|
pub fn clean_comment_tail(text : String) -> String {
  let trimmed = trim_ascii(text)
  let without_block = text_replace(trimmed, "*/", "")
  trim_ascii(without_block)
}

///|
pub fn scan_source(path : String, source : String) -> SourceLicense {
  match extract_spdx_expression(source) {
    Some(expr) => {
      let valid = is_valid(expr)
      source_license(
        path,
        normalize(expr),
        true,
        valid,
        if valid {
          "ok"
        } else {
          validation_report(expr)
        },
      )
    }
    None =>
      source_license(path, "", false, false, "missing SPDX-License-Identifier")
  }
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
