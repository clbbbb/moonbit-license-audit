// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn summary(text : String) -> String {
  match parse(text).expr {
    Some(expr) =>
      "normalized=" +
      format(expr) +
      "\nlicenses=" +
      join_with(licenses(expr), ",") +
      "\nexceptions=" +
      join_with(exceptions(expr), ",") +
      "\nvalidation=" +
      validation_report(text)
    None => "error=" + parse(text).error
  }
}

///|
pub fn markdown_report(text : String) -> String {
  match parse(text).expr {
    Some(expr) =>
      join_lines([
        "# SPDX expression report",
        "",
        "- normalized: `" + format(expr) + "`",
        "- licenses: `" + join_with(licenses(expr), ",") + "`",
        "- exceptions: `" + join_with(exceptions(expr), ",") + "`",
        "- validation: `" + validation_report(text) + "`",
        "",
        "```text",
        tree(expr),
        "```",
      ])
    None => "# SPDX expression report\n\nparse error: " + parse(text).error
  }
}

///|
pub fn csv_report(text : String) -> String {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = ["kind,value"]
      for id in licenses(expr) {
        rows.push("license," + id)
      }
      for ex in exceptions(expr) {
        rows.push("exception," + ex)
      }
      join_lines(rows)
    }
    None => "error," + parse(text).error
  }
}
