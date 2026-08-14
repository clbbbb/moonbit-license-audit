// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub struct LicenseProfile {
  id : String
  family : String
  osi : Bool
  copyleft : Bool
  risk : String
  note : String
} derive(Debug, Eq)

///|
pub fn license_profile(id : String) -> LicenseProfile {
  let canonical = canonical_license(id)
  {
    id: canonical,
    family: license_family(canonical),
    osi: is_osi_license(canonical),
    copyleft: is_copyleft_license(canonical),
    risk: license_risk(canonical),
    note: license_note(canonical),
  }
}

///|
pub fn license_family(id : String) -> String {
  let value = canonical_license(id)
  if value == "MIT" || value == "ISC" || value == "0BSD" || value == "Zlib" {
    "permissive"
  } else if value == "Apache-2.0" || value == "BSL-1.0" {
    "permissive-patent"
  } else if value == "BSD-2-Clause" || value == "BSD-3-Clause" {
    "permissive-notice"
  } else if value == "MPL-2.0" || value == "EPL-2.0" || value == "CDDL-1.0" {
    "file-level-copyleft"
  } else if value.has_prefix("LGPL") {
    "weak-copyleft"
  } else if value.has_prefix("GPL") {
    "strong-copyleft"
  } else if value == "CC0-1.0" || value == "Unlicense" {
    "public-domain-style"
  } else {
    "unknown"
  }
}

///|
pub fn license_risk(id : String) -> String {
  let family = license_family(id)
  if family == "unknown" {
    "unknown"
  } else if family == "strong-copyleft" {
    "high"
  } else if family == "weak-copyleft" || family == "file-level-copyleft" {
    "medium"
  } else {
    "low"
  }
}

///|
pub fn license_note(id : String) -> String {
  let value = canonical_license(id)
  if value == "MIT" {
    "short permissive license, keep copyright and license notice"
  } else if value == "Apache-2.0" {
    "permissive license with explicit patent grant and NOTICE handling"
  } else if value == "BSD-2-Clause" || value == "BSD-3-Clause" {
    "permissive BSD license, keep copyright and disclaimer"
  } else if value == "ISC" || value == "0BSD" || value == "Zlib" {
    "small permissive license commonly used by libraries"
  } else if value == "MPL-2.0" {
    "file-level copyleft, modified MPL files stay under MPL"
  } else if value == "EPL-2.0" {
    "file/module oriented copyleft used by Eclipse projects"
  } else if value.has_prefix("LGPL") {
    "weak copyleft, pay attention to linking and relinking obligations"
  } else if value.has_prefix("GPL") {
    "strong copyleft, distribution may require whole derivative source"
  } else if value == "CC0-1.0" || value == "Unlicense" {
    "public-domain-style terms, not always OSI-approved in this catalog"
  } else {
    "not in the compact catalog"
  }
}

///|
pub fn profile_row(id : String) -> String {
  let p = license_profile(id)
  p.id +
  "," +
  p.family +
  "," +
  bool_word(p.osi) +
  "," +
  bool_word(p.copyleft) +
  "," +
  p.risk
}

///|
pub fn profile_table(text : String) -> String {
  match parse(text).expr {
    Some(expr) => {
      let rows : Array[String] = ["license,family,osi,copyleft,risk"]
      for id in licenses(expr) {
        rows.push(profile_row(id))
      }
      join_lines(rows)
    }
    None => "error," + parse(text).error
  }
}

///|
pub fn bool_word(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
pub fn highest_risk(text : String) -> String {
  match parse(text).expr {
    Some(expr) => {
      let mut result = "low"
      for id in licenses(expr) {
        let risk = license_risk(id)
        if risk == "unknown" {
          return "unknown"
        }
        if risk == "high" {
          result = "high"
        } else if risk == "medium" && result == "low" {
          result = "medium"
        }
      }
      result
    }
    None => "unknown"
  }
}
