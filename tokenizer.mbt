// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn tokenize(text : String) -> Array[Token] {
  let tokens : Array[Token] = []
  let mut current = ""
  let mut start = 0
  fn flush(end_offset : Int) {
    if current != "" {
      tokens.push(token_from_word(current, start))
      current = ""
    }
    ignore(end_offset)
  }
  for index, ch in text {
    if ascii_space(ch) {
      flush(index)
    } else if ch == '(' {
      flush(index)
      tokens.push({ kind: LParen, text: "(", offset: index })
    } else if ch == ')' {
      flush(index)
      tokens.push({ kind: RParen, text: ")", offset: index })
    } else {
      if current == "" {
        start = index
      }
      current = current + [ch]
    }
  }
  flush(text.length())
  tokens
}

///|
pub fn token_from_word(word : String, offset : Int) -> Token {
  let upper = upper_ascii(word)
  if upper == "AND" {
    { kind: AndTok, text: word, offset }
  } else if upper == "OR" {
    { kind: OrTok, text: word, offset }
  } else if upper == "WITH" {
    { kind: WithTok, text: word, offset }
  } else {
    { kind: Ident(word), text: word, offset }
  }
}

///|
pub fn tokens_report(text : String) -> String {
  let rows : Array[String] = []
  for token in tokenize(text) {
    rows.push(token.text + "@" + token.offset.to_string())
  }
  join_lines(rows)
}
