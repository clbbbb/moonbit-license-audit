// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn format(expr : Expr) -> String {
  format_prec(expr, 0)
}

///|
pub fn format_prec(expr : Expr, parent : Int) -> String {
  match expr {
    License(id) => id
    LicenseWithException(id, ex) => id + " WITH " + ex
    And(left, right) =>
      wrap_if(
        parent > 2,
        format_prec(left, 2) + " AND " + format_prec(right, 2),
      )
    Or(left, right) =>
      wrap_if(parent > 1, format_prec(left, 1) + " OR " + format_prec(right, 1))
  }
}

///|
pub fn wrap_if(cond : Bool, text : String) -> String {
  if cond {
    "(" + text + ")"
  } else {
    text
  }
}

///|
pub fn normalize(text : String) -> String {
  match parse(text).expr {
    Some(expr) => format(expr)
    None => ""
  }
}

///|
pub fn tree(expr : Expr) -> String {
  match expr {
    License(id) => "License(" + id + ")"
    LicenseWithException(id, ex) => "With(" + id + "," + ex + ")"
    And(left, right) => "And(" + tree(left) + "," + tree(right) + ")"
    Or(left, right) => "Or(" + tree(left) + "," + tree(right) + ")"
  }
}

///|
pub fn parse_tree(text : String) -> String {
  match parse(text).expr {
    Some(expr) => tree(expr)
    None => "error"
  }
}
