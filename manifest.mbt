// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn extract_moon_mod_license(text : String) -> String? {
  extract_quoted_value(text, "license")
}

///|
pub fn extract_moon_mod_name(text : String) -> String? {
  extract_quoted_value(text, "name")
}

///|
pub fn extract_quoted_value(text : String, field : String) -> String? {
  for line in split_char(text, '\n') {
    match extract_quoted_value_line(line, field) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
pub fn extract_quoted_value_line(line : String, field : String) -> String? {
  let trimmed = trim_ascii(line)
  let colon = field + ":"
  let equals = field + " ="
  let compact_equals = field + "="
  if trimmed.has_prefix(colon) {
    quoted_prefix(
      trimmed.unsafe_substring(start=colon.length(), end=trimmed.length()),
    )
  } else if trimmed.has_prefix(equals) {
    quoted_prefix(
      trimmed.unsafe_substring(start=equals.length(), end=trimmed.length()),
    )
  } else if trimmed.has_prefix(compact_equals) {
    quoted_prefix(
      trimmed.unsafe_substring(
        start=compact_equals.length(),
        end=trimmed.length(),
      ),
    )
  } else {
    None
  }
}

///|
pub fn quoted_prefix(text : String) -> String? {
  let trimmed = trim_ascii(text)
  if trimmed.length() < 2 {
    return None
  }
  let mut open = -1
  let mut close = -1
  for index, ch in trimmed {
    if ch == '"' {
      if open < 0 {
        open = index
      } else {
        close = index
        break
      }
    }
  }
  if open >= 0 && close > open {
    Some(trimmed.unsafe_substring(start=open + 1, end=close))
  } else {
    None
  }
}

///|
pub fn moon_mod_license_report(text : String) -> String {
  match extract_moon_mod_license(text) {
    Some(expr) =>
      if is_valid(expr) {
        "ok " + normalize(expr)
      } else {
        "invalid license field: " + validation_report(expr)
      }
    None => "missing license field"
  }
}

///|
pub fn readme_mentions_license(readme : String, expr : String) -> Bool {
  let lower_readme = lower_ascii(readme)
  for id in licenses(parse_or_panic(expr)) {
    match lower_readme.find(lower_ascii(id)) {
      Some(_) => return true
      None => ()
    }
  }
  false
}

///|
pub fn package_audit_report(moon_mod : String, readme : String) -> String {
  match extract_moon_mod_license(moon_mod) {
    Some(expr) => {
      let lines : Array[String] = [
        "moon.mod license: " + moon_mod_license_report(moon_mod),
      ]
      if readme_mentions_license(readme, expr) {
        lines.push("README license mention: ok")
      } else {
        lines.push("README license mention: missing")
      }
      lines.push("review level: " + review_level(expr))
      join_lines(lines)
    }
    None => "moon.mod license: missing license field"
  }
}

///|
pub fn moon_mod_has_repository(text : String) -> Bool {
  extract_quoted_value(text, "repository") is Some(_)
}

///|
pub fn moon_mod_has_readme(text : String) -> Bool {
  extract_quoted_value(text, "readme") is Some(_)
}

///|
pub fn moon_mod_metadata_report(text : String) -> String {
  let rows : Array[String] = []
  match extract_moon_mod_name(text) {
    Some(name) => rows.push("name: " + name)
    None => rows.push("name: missing")
  }
  match extract_moon_mod_license(text) {
    Some(license) => rows.push("license: " + normalize(license))
    None => rows.push("license: missing")
  }
  rows.push(
    if moon_mod_has_repository(text) {
      "repository: ok"
    } else {
      "repository: missing"
    },
  )
  rows.push(
    if moon_mod_has_readme(text) {
      "readme: ok"
    } else {
      "readme: missing"
    },
  )
  join_lines(rows)
}
