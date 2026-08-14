// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub(all) enum Expr {
  License(String)
  LicenseWithException(String, String)
  And(Expr, Expr)
  Or(Expr, Expr)
} derive(Debug, Eq)

///|
pub(all) enum TokenKind {
  Ident(String)
  AndTok
  OrTok
  WithTok
  LParen
  RParen
} derive(Debug, Eq)

///|
pub struct Token {
  kind : TokenKind
  text : String
  offset : Int
} derive(Debug, Eq)

///|
pub struct ParseResult {
  ok : Bool
  expr : Expr?
  error : String
} derive(Debug, Eq)

///|
pub fn license(id : String) -> Expr {
  License(canonical_license(id))
}

///|
pub fn with_exception(id : String, exception : String) -> Expr {
  LicenseWithException(canonical_license(id), canonical_exception(exception))
}

///|
pub fn and_expr(left : Expr, right : Expr) -> Expr {
  And(left, right)
}

///|
pub fn or_expr(left : Expr, right : Expr) -> Expr {
  Or(left, right)
}

///|
pub fn ok(expr : Expr) -> ParseResult {
  { ok: true, expr: Some(expr), error: "" }
}

///|
pub fn fail(message : String) -> ParseResult {
  { ok: false, expr: None, error: message }
}
