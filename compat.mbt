///|
pub fn compatible_for_distribution(text : String) -> Bool {
  compatibility_errors(text).is_empty()
}

///|
pub fn compatibility_errors(text : String) -> Array[String] {
  let errors : Array[String] = []
  match parse(text).expr {
    Some(expr) => {
      if contains_strong_copyleft(expr) && contains_public_domain_style(expr) {
        errors.push(
          "review strong copyleft combined with public-domain-style terms",
        )
      }
      if contains_string(licenses(expr), "CDDL-1.0") &&
        contains_strong_copyleft(expr) {
        errors.push("CDDL and GPL-style terms usually require manual review")
      }
      if contains_string(licenses(expr), "Apache-2.0") &&
        contains_string(licenses(expr), "GPL-2.0-only") {
        errors.push("Apache-2.0 is not normally compatible with GPL-2.0-only")
      }
      for id in licenses(expr) {
        if !is_known_license(id) {
          errors.push("unknown license blocks compatibility decision: " + id)
        }
      }
    }
    None => errors.push("parse error: " + parse(text).error)
  }
  errors
}

///|
pub fn compatibility_report(text : String) -> String {
  let errors = compatibility_errors(text)
  if errors.is_empty() {
    "ok"
  } else {
    join_lines(errors)
  }
}

///|
pub fn contains_strong_copyleft(expr : Expr) -> Bool {
  for id in licenses(expr) {
    if license_family(id) == "strong-copyleft" {
      return true
    }
  }
  false
}

///|
pub fn contains_public_domain_style(expr : Expr) -> Bool {
  for id in licenses(expr) {
    if license_family(id) == "public-domain-style" {
      return true
    }
  }
  false
}

///|
pub fn review_level(text : String) -> String {
  if !is_valid(text) {
    return "invalid"
  }
  let risk = highest_risk(text)
  if risk == "high" {
    "legal-review"
  } else if risk == "medium" {
    "maintainer-review"
  } else if !compatible_for_distribution(text) {
    "legal-review"
  } else {
    "fast-path"
  }
}
