// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub struct Diagnostic {
  severity : String
  message : String
  suggestion : String
} derive(Debug, Eq)

///|
pub fn diagnostic(
  severity : String,
  message : String,
  suggestion : String,
) -> Diagnostic {
  { severity, message, suggestion }
}

///|
pub fn diagnostics(text : String) -> Array[Diagnostic] {
  let items : Array[Diagnostic] = []
  let parsed = parse(text)
  match parsed.expr {
    Some(expr) => {
      for id in licenses(expr) {
        if !is_known_license(id) {
          items.push(
            diagnostic(
              "error",
              "unknown license: " + id,
              license_suggestion(id),
            ),
          )
        } else if is_deprecated_license(id) {
          items.push(
            diagnostic("warning", "deprecated SPDX license id: " + id, ""),
          )
        }
      }
      for ex in exceptions(expr) {
        if !is_known_exception(ex) {
          items.push(
            diagnostic(
              "error",
              "unknown exception: " + ex,
              exception_suggestion(ex),
            ),
          )
        } else if is_deprecated_exception(ex) {
          items.push(
            diagnostic("warning", "deprecated SPDX exception id: " + ex, ""),
          )
        }
      }
      if contains_string(operators(expr), "OR") {
        items.push(
          diagnostic(
            "info", "expression contains OR alternatives", "policy checks should accept the expression when at least one branch is allowed",
          ),
        )
      }
    }
    None =>
      items.push(
        diagnostic(
          "error",
          parsed.error,
          "check SPDX operator spelling and parentheses",
        ),
      )
  }
  items
}

///|
pub fn diagnostics_report(text : String) -> String {
  let rows : Array[String] = []
  for item in diagnostics(text) {
    rows.push(item.severity + ": " + item.message + suggestion_suffix(item))
  }
  if rows.is_empty() {
    "ok"
  } else {
    join_lines(rows)
  }
}

///|
pub fn suggestion_suffix(item : Diagnostic) -> String {
  if item.suggestion == "" {
    ""
  } else {
    " (" + item.suggestion + ")"
  }
}

///|
pub fn license_suggestion(id : String) -> String {
  let value = lower_ascii(id)
  let common = common_license_alias(value)
  if common != "" {
    return "did you mean " + common + "?"
  }
  for known in known_licenses() {
    let candidate = lower_ascii(known)
    if candidate == value {
      return "use canonical id " + known
    }
    if !is_deprecated_license(known) &&
      (candidate.has_prefix(value) || value.has_prefix(candidate)) {
      return "did you mean " + known + "?"
    }
  }
  for known in known_licenses() {
    let candidate = lower_ascii(known)
    match candidate.find(value) {
      Some(_) if !is_deprecated_license(known) =>
        return "did you mean " + known + "?"
      Some(_) => ()
      None => ()
    }
  }
  ""
}

///|
pub fn common_license_alias(value : String) -> String {
  if value == "apache" || value == "apache2" {
    "Apache-2.0"
  } else if value == "bsd" {
    "BSD-3-Clause"
  } else if value == "gpl3" {
    "GPL-3.0-only"
  } else if value == "gpl2" {
    "GPL-2.0-only"
  } else if value == "lgpl3" {
    "LGPL-3.0-only"
  } else if value == "mpl" {
    "MPL-2.0"
  } else {
    ""
  }
}

///|
pub fn exception_suggestion(id : String) -> String {
  let value = lower_ascii(id)
  for known in known_exceptions() {
    let candidate = lower_ascii(known)
    if candidate == value {
      return "use canonical id " + known
    }
    if candidate.has_prefix(value) || value.has_prefix(candidate) {
      return "did you mean " + known + "?"
    }
  }
  ""
}

///|
pub fn quick_fix(text : String) -> String {
  let parsed = parse(text)
  match parsed.expr {
    Some(expr) => format(expr)
    None => text
  }
}
