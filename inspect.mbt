// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn licenses(expr : Expr) -> Array[String] {
  match expr {
    License(id) => [id]
    LicenseWithException(id, _) => [id]
    And(left, right) => unique_strings(licenses(left) + licenses(right))
    Or(left, right) => unique_strings(licenses(left) + licenses(right))
  }
}

///|
pub fn exceptions(expr : Expr) -> Array[String] {
  match expr {
    License(_) => []
    LicenseWithException(_, ex) => [ex]
    And(left, right) => unique_strings(exceptions(left) + exceptions(right))
    Or(left, right) => unique_strings(exceptions(left) + exceptions(right))
  }
}

///|
pub fn operators(expr : Expr) -> Array[String] {
  match expr {
    License(_) => []
    LicenseWithException(_, _) => ["WITH"]
    And(left, right) =>
      unique_strings(["AND"] + operators(left) + operators(right))
    Or(left, right) =>
      unique_strings(["OR"] + operators(left) + operators(right))
  }
}

///|
pub fn depth(expr : Expr) -> Int {
  match expr {
    License(_) | LicenseWithException(_, _) => 1
    And(left, right) | Or(left, right) => 1 + max_int(depth(left), depth(right))
  }
}

///|
pub fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn expression_stats(text : String) -> String {
  match parse(text).expr {
    Some(expr) =>
      "licenses=" +
      licenses(expr).length().to_string() +
      "\nexceptions=" +
      exceptions(expr).length().to_string() +
      "\noperators=" +
      operators(expr).length().to_string() +
      "\ndepth=" +
      depth(expr).to_string()
    None => "error"
  }
}

///|
pub fn contains_license(expr : Expr, id : String) -> Bool {
  contains_string(licenses(expr), canonical_license(id))
}

///|
pub fn contains_exception(expr : Expr, id : String) -> Bool {
  contains_string(exceptions(expr), canonical_exception(id))
}
