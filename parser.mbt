///|
pub fn parse(text : String) -> ParseResult {
  let tokens = tokenize(text)
  if tokens.is_empty() {
    return fail("empty expression")
  }
  let state = parse_or(tokens, 0)
  match state.expr {
    Some(expr) if state.index == tokens.length() => ok(expr)
    Some(_) => fail("unexpected token: " + tokens[state.index].text)
    None => fail(state.error)
  }
}

///|
pub struct ParseState {
  expr : Expr?
  index : Int
  error : String
} derive(Debug, Eq)

///|
pub fn state(expr : Expr, index : Int) -> ParseState {
  { expr: Some(expr), index, error: "" }
}

///|
pub fn state_error(message : String, index : Int) -> ParseState {
  { expr: None, index, error: message }
}

///|
pub fn parse_or(tokens : Array[Token], start : Int) -> ParseState {
  let mut left = parse_and(tokens, start)
  while left.expr is Some(_) && left.index < tokens.length() {
    if tokens[left.index].kind is OrTok {
      let right = parse_and(tokens, left.index + 1)
      match (left.expr, right.expr) {
        (Some(a), Some(b)) => left = state(Or(a, b), right.index)
        _ => return right
      }
    } else {
      break
    }
  }
  left
}

///|
pub fn parse_and(tokens : Array[Token], start : Int) -> ParseState {
  let mut left = parse_primary(tokens, start)
  while left.expr is Some(_) && left.index < tokens.length() {
    if tokens[left.index].kind is AndTok {
      let right = parse_primary(tokens, left.index + 1)
      match (left.expr, right.expr) {
        (Some(a), Some(b)) => left = state(And(a, b), right.index)
        _ => return right
      }
    } else {
      break
    }
  }
  left
}

///|
pub fn parse_primary(tokens : Array[Token], start : Int) -> ParseState {
  if start >= tokens.length() {
    return state_error("expected license id", start)
  }
  match tokens[start].kind {
    Ident(id) => parse_license_tail(tokens, start + 1, canonical_license(id))
    LParen => {
      let inner = parse_or(tokens, start + 1)
      match inner.expr {
        Some(expr) if inner.index < tokens.length() &&
          tokens[inner.index].kind is RParen => state(expr, inner.index + 1)
        Some(_) => state_error("expected ')'", inner.index)
        None => inner
      }
    }
    _ => state_error("expected license id", start)
  }
}

///|
pub fn parse_license_tail(
  tokens : Array[Token],
  index : Int,
  id : String,
) -> ParseState {
  if index + 1 < tokens.length() && tokens[index].kind is WithTok {
    match tokens[index + 1].kind {
      Ident(ex) =>
        state(LicenseWithException(id, canonical_exception(ex)), index + 2)
      _ => state_error("expected exception id after WITH", index + 1)
    }
  } else {
    state(License(id), index)
  }
}

///|
pub fn parse_or_panic(text : String) -> Expr {
  match parse(text).expr {
    Some(expr) => expr
    None => License("INVALID")
  }
}
