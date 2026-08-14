// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn validation_errors(text : String) -> Array[String] {
  let result = parse(text)
  match result.expr {
    Some(expr) => validation_errors_expr(expr)
    None => [result.error]
  }
}

///|
pub fn validation_errors_expr(expr : Expr) -> Array[String] {
  let errors : Array[String] = []
  for id in licenses(expr) {
    if !is_known_license(id) {
      errors.push("unknown license: " + id)
    }
  }
  for ex in exceptions(expr) {
    if !is_known_exception(ex) {
      errors.push("unknown exception: " + ex)
    }
  }
  errors
}

///|
pub fn validation_report(text : String) -> String {
  let errors = validation_errors(text)
  if errors.is_empty() {
    "ok"
  } else {
    join_lines(errors)
  }
}

///|
pub fn is_valid(text : String) -> Bool {
  validation_errors(text).is_empty()
}

///|
pub fn unknown_licenses(text : String) -> Array[String] {
  match parse(text).expr {
    Some(expr) => {
      let result : Array[String] = []
      for id in licenses(expr) {
        if !is_known_license(id) {
          result.push(id)
        }
      }
      result
    }
    None => []
  }
}

///|
pub fn unknown_exceptions(text : String) -> Array[String] {
  match parse(text).expr {
    Some(expr) => {
      let result : Array[String] = []
      for ex in exceptions(expr) {
        if !is_known_exception(ex) {
          result.push(ex)
        }
      }
      result
    }
    None => []
  }
}
