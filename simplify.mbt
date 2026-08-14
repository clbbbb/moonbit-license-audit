// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn simplify_text(text : String) -> String {
  match parse(text).expr {
    Some(expr) => format(simplify_expr(expr))
    None => ""
  }
}

///|
pub fn simplify_expr(expr : Expr) -> Expr {
  match expr {
    License(id) => License(canonical_license(id))
    LicenseWithException(id, ex) =>
      LicenseWithException(canonical_license(id), canonical_exception(ex))
    And(left, right) => simplify_and(simplify_expr(left), simplify_expr(right))
    Or(left, right) => simplify_or(simplify_expr(left), simplify_expr(right))
  }
}

///|
pub fn simplify_and(left : Expr, right : Expr) -> Expr {
  if format(left) == format(right) {
    left
  } else {
    And(left, right)
  }
}

///|
pub fn simplify_or(left : Expr, right : Expr) -> Expr {
  if format(left) == format(right) {
    left
  } else {
    Or(left, right)
  }
}

///|
pub fn alternatives(expr : Expr) -> Array[Expr] {
  match expr {
    Or(left, right) => alternatives(left) + alternatives(right)
    _ => [expr]
  }
}

///|
pub fn requirements(expr : Expr) -> Array[Expr] {
  match expr {
    And(left, right) => requirements(left) + requirements(right)
    _ => [expr]
  }
}

///|
pub fn alternative_texts(text : String) -> Array[String] {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = []
      for item in alternatives(expr) {
        rows.push(format(simplify_expr(item)))
      }
      unique_strings(rows)
    }
    None => []
  }
}

///|
pub fn requirement_texts(text : String) -> Array[String] {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = []
      for item in requirements(expr) {
        rows.push(format(simplify_expr(item)))
      }
      unique_strings(rows)
    }
    None => []
  }
}

///|
pub fn expression_shape(text : String) -> String {
  match parse(text).expr {
    Some(expr) => expression_shape_expr(expr)
    None => "invalid"
  }
}

///|
pub fn expression_shape_expr(expr : Expr) -> String {
  match expr {
    License(_) => "single"
    LicenseWithException(_, _) => "single-with-exception"
    And(_, _) if contains_string(operators(expr), "OR") => "mixed"
    And(_, _) => "all-of"
    Or(_, _) if contains_string(operators(expr), "AND") => "mixed"
    Or(_, _) => "any-of"
  }
}

///|
pub fn choice_count(text : String) -> Int {
  match parse(text).expr {
    Some(expr) => alternatives(expr).length()
    None => 0
  }
}

///|
pub fn requirement_count(text : String) -> Int {
  match parse(text).expr {
    Some(expr) => requirements(expr).length()
    None => 0
  }
}

///|
pub fn explain_expression(text : String) -> String {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = [
        "normalized: " + format(expr),
        "simplified: " + format(simplify_expr(expr)),
        "shape: " + expression_shape_expr(expr),
        "alternatives: " + join_with(alternative_texts(text), " | "),
        "requirements: " + join_with(requirement_texts(text), " + "),
      ]
      join_lines(rows)
    }
    None => "parse error: " + parse(text).error
  }
}
