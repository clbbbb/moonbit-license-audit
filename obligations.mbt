///|
pub struct Obligation {
  key : String
  title : String
  detail : String
  severity : String
} derive(Debug, Eq)

///|
pub fn obligation(
  key : String,
  title : String,
  detail : String,
  severity : String,
) -> Obligation {
  { key, title, detail, severity }
}

///|
pub fn obligations_for_license(id : String) -> Array[Obligation] {
  let license = canonical_license(id)
  if license == "MIT" ||
    license == "ISC" ||
    license == "BSD-2-Clause" ||
    license == "BSD-3-Clause" ||
    license == "Zlib" ||
    license == "0BSD" {
    permissive_obligations(license)
  } else if license == "Apache-2.0" {
    apache_obligations()
  } else if license == "MPL-2.0" ||
    license == "EPL-2.0" ||
    license == "CDDL-1.0" {
    file_copyleft_obligations(license)
  } else if license.has_prefix("LGPL") {
    weak_copyleft_obligations(license)
  } else if license.has_prefix("GPL") {
    strong_copyleft_obligations(license)
  } else if license == "CC0-1.0" || license == "Unlicense" {
    public_domain_style_obligations(license)
  } else {
    [
      obligation(
        "manual-review", "Manual license review", "The license is not in the compact catalog; review the original text before release.",
        "high",
      ),
    ]
  }
}

///|
pub fn permissive_obligations(id : String) -> Array[Obligation] {
  [
    obligation(
      "keep-notice",
      "Keep copyright and license notice",
      id +
      " is permissive, but redistribution should keep the copyright and license text.",
      "medium",
    ),
    obligation(
      "keep-disclaimer", "Keep warranty disclaimer", "Do not remove the warranty and liability disclaimer from redistributed copies.",
      "low",
    ),
  ]
}

///|
pub fn apache_obligations() -> Array[Obligation] {
  [
    obligation(
      "keep-license", "Keep Apache-2.0 license text", "Redistribution should include the Apache-2.0 license text.",
      "medium",
    ),
    obligation(
      "notice-file", "Preserve NOTICE information", "If upstream provides a NOTICE file, keep required attribution notices.",
      "medium",
    ),
    obligation(
      "state-changes", "Mark modified files", "Apache-2.0 asks redistributors to state significant changes to files.",
      "medium",
    ),
    obligation(
      "patent-termination", "Respect patent termination clause", "Patent litigation can terminate the patent grant; flag legal review when relevant.",
      "low",
    ),
  ]
}

///|
pub fn file_copyleft_obligations(id : String) -> Array[Obligation] {
  [
    obligation(
      "publish-modified-files",
      "Publish modified covered files",
      id +
      " is file-level copyleft; modified covered files usually stay under the same license.",
      "high",
    ),
    obligation(
      "keep-boundary", "Keep file-level boundary clear", "Track which files are covered so unrelated files are not accidentally over-scoped.",
      "medium",
    ),
    obligation(
      "include-license", "Include license text", "Redistribution should include the relevant license text and notices.",
      "medium",
    ),
  ]
}

///|
pub fn weak_copyleft_obligations(id : String) -> Array[Obligation] {
  [
    obligation(
      "linking-review",
      "Review linking model",
      id +
      " is weak copyleft; binary distribution may need relinking or object-file handling.",
      "high",
    ),
    obligation(
      "publish-library-changes", "Publish changes to the library", "Changes to the covered library generally need to remain under the same license.",
      "high",
    ),
    obligation(
      "include-license", "Include license text", "Keep license text and notices with redistributed artifacts.",
      "medium",
    ),
  ]
}

///|
pub fn strong_copyleft_obligations(id : String) -> Array[Obligation] {
  [
    obligation(
      "source-offer",
      "Provide corresponding source",
      id +
      " is strong copyleft; distribution may require complete corresponding source.",
      "high",
    ),
    obligation(
      "derivative-scope-review", "Review derivative work scope", "Check whether combined work must be distributed under compatible copyleft terms.",
      "high",
    ),
    obligation(
      "include-license", "Include license text", "Keep license text, notices, and source availability information.",
      "medium",
    ),
  ]
}

///|
pub fn public_domain_style_obligations(id : String) -> Array[Obligation] {
  [
    obligation(
      "jurisdiction-review",
      "Review public-domain-style terms",
      id +
      " may behave differently across jurisdictions; keep the original text for traceability.",
      "medium",
    ),
  ]
}

///|
pub fn obligations_for_expr(expr : Expr) -> Array[Obligation] {
  let rows : Array[Obligation] = []
  for id in licenses(expr) {
    for item in obligations_for_license(id) {
      if !contains_obligation(rows, item.key) {
        rows.push(item)
      }
    }
  }
  rows
}

///|
pub fn contains_obligation(items : Array[Obligation], key : String) -> Bool {
  for item in items {
    if item.key == key {
      return true
    }
  }
  false
}

///|
pub fn obligations_report(text : String) -> String {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = []
      for item in obligations_for_expr(expr) {
        rows.push(item.severity + ": " + item.title + " - " + item.detail)
      }
      if rows.is_empty() {
        "no obligations"
      } else {
        join_lines(rows)
      }
    }
    None => "parse error: " + parse(text).error
  }
}

///|
pub fn notice_checklist(text : String) -> Array[String] {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = []
      for item in obligations_for_expr(expr) {
        if item.key == "keep-notice" ||
          item.key == "notice-file" ||
          item.key == "include-license" {
          rows.push(item.title)
        }
      }
      unique_strings(rows)
    }
    None => []
  }
}

///|
pub fn notice_checklist_report(text : String) -> String {
  let rows = notice_checklist(text)
  if rows.is_empty() {
    "no notice checklist"
  } else {
    join_lines(rows)
  }
}
