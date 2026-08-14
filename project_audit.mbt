///|
pub struct ProjectAudit {
  package_name : String
  package_license : String
  readme_ok : Bool
  source_count : Int
  missing_headers : Int
  invalid_headers : Int
  policy_errors : Array[String]
  warnings : Array[String]
} derive(Debug, Eq)

///|
pub fn project_audit(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> ProjectAudit {
  let package_name = option_or(extract_moon_mod_name(moon_mod), "unknown")
  let package_license = option_or(extract_moon_mod_license(moon_mod), "")
  let source_results = scan_sources(paths, sources)
  let warnings : Array[String] = []
  let policy_items : Array[String] = []
  collect_manifest_findings(
    moon_mod, readme, package_license, warnings, policy_items, policy,
  )
  collect_source_findings(source_results, warnings, policy_items, policy)
  {
    package_name,
    package_license: normalize(package_license),
    readme_ok: readme_mentions_license_safe(readme, package_license),
    source_count: source_results.length(),
    missing_headers: count_missing_headers(source_results),
    invalid_headers: count_invalid_headers(source_results),
    policy_errors: unique_strings(policy_items),
    warnings: unique_strings(warnings),
  }
}

///|
pub fn option_or(value : String?, fallback : String) -> String {
  match value {
    Some(item) => item
    None => fallback
  }
}

///|
pub fn collect_manifest_findings(
  moon_mod : String,
  readme : String,
  package_license : String,
  warnings : Array[String],
  policy_items : Array[String],
  policy : Policy,
) -> Unit {
  if extract_moon_mod_name(moon_mod) is None {
    warnings.push("moon.mod name is missing")
  }
  if package_license == "" {
    policy_items.push("moon.mod license is missing")
  } else {
    for item in validation_errors(package_license) {
      policy_items.push("moon.mod license: " + item)
    }
    for item in policy_errors(package_license, policy) {
      policy_items.push("moon.mod license: " + item)
    }
    if !readme_mentions_license_safe(readme, package_license) {
      warnings.push("README does not mention the declared license")
    }
  }
  if !moon_mod_has_repository(moon_mod) {
    warnings.push("moon.mod repository is missing")
  }
}

///|
pub fn collect_source_findings(
  results : Array[SourceLicense],
  warnings : Array[String],
  policy_items : Array[String],
  policy : Policy,
) -> Unit {
  for item in results {
    if !item.found {
      warnings.push(item.path + ": missing SPDX header")
    } else if !item.valid {
      policy_items.push(item.path + ": " + item.message)
    } else {
      for error in policy_errors(item.expression, policy) {
        policy_items.push(item.path + ": " + error)
      }
    }
  }
}

///|
pub fn readme_mentions_license_safe(readme : String, expr : String) -> Bool {
  if expr == "" || !is_valid(expr) {
    false
  } else {
    readme_mentions_license(readme, expr)
  }
}

///|
pub fn count_missing_headers(results : Array[SourceLicense]) -> Int {
  let mut count = 0
  for item in results {
    if !item.found {
      count = count + 1
    }
  }
  count
}

///|
pub fn count_invalid_headers(results : Array[SourceLicense]) -> Int {
  let mut count = 0
  for item in results {
    if item.found && !item.valid {
      count = count + 1
    }
  }
  count
}

///|
pub fn audit_passes(audit : ProjectAudit) -> Bool {
  audit.policy_errors.is_empty() &&
  audit.missing_headers == 0 &&
  audit.invalid_headers == 0
}

///|
pub fn audit_score(audit : ProjectAudit) -> Int {
  let mut score = 100
  score = score - audit.policy_errors.length() * 15
  score = score - audit.warnings.length() * 5
  score = score - audit.missing_headers * 8
  score = score - audit.invalid_headers * 12
  if score < 0 {
    0
  } else {
    score
  }
}

///|
pub fn audit_grade(audit : ProjectAudit) -> String {
  let score = audit_score(audit)
  if score >= 90 {
    "A"
  } else if score >= 75 {
    "B"
  } else if score >= 60 {
    "C"
  } else {
    "D"
  }
}

///|
pub fn project_audit_report(audit : ProjectAudit) -> String {
  let rows : Array[String] = [
    "package: " + audit.package_name,
    "license: " + audit.package_license,
    "grade: " + audit_grade(audit),
    "score: " + audit_score(audit).to_string(),
    "sources: " + audit.source_count.to_string(),
    "missing headers: " + audit.missing_headers.to_string(),
    "invalid headers: " + audit.invalid_headers.to_string(),
  ]
  push_section(rows, "policy errors", audit.policy_errors)
  push_section(rows, "warnings", audit.warnings)
  join_lines(rows)
}

///|
pub fn push_section(
  rows : Array[String],
  title : String,
  items : Array[String],
) -> Unit {
  if items.is_empty() {
    rows.push(title + ": none")
  } else {
    rows.push(title + ":")
    for item in items {
      rows.push("- " + item)
    }
  }
}

///|
pub fn project_audit_markdown(audit : ProjectAudit) -> String {
  let rows : Array[String] = [
    "# License audit report",
    "",
    "- package: `" + audit.package_name + "`",
    "- license: `" + audit.package_license + "`",
    "- grade: `" + audit_grade(audit) + "`",
    "- score: `" + audit_score(audit).to_string() + "`",
    "- source files: `" + audit.source_count.to_string() + "`",
    "- missing SPDX headers: `" + audit.missing_headers.to_string() + "`",
    "- invalid SPDX headers: `" + audit.invalid_headers.to_string() + "`",
    "",
  ]
  push_markdown_section(rows, "Policy errors", audit.policy_errors)
  push_markdown_section(rows, "Warnings", audit.warnings)
  join_lines(rows)
}

///|
pub fn push_markdown_section(
  rows : Array[String],
  title : String,
  items : Array[String],
) -> Unit {
  rows.push("## " + title)
  rows.push("")
  if items.is_empty() {
    rows.push("- none")
  } else {
    for item in items {
      rows.push("- " + item)
    }
  }
  rows.push("")
}

///|
pub fn audit_project_report(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> String {
  project_audit_report(project_audit(moon_mod, readme, paths, sources, policy))
}
