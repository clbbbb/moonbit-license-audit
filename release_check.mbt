///|
pub struct ReleaseItem {
  name : String
  passed : Bool
  detail : String
} derive(Debug, Eq)

///|
pub fn release_item(
  name : String,
  passed : Bool,
  detail : String,
) -> ReleaseItem {
  { name, passed, detail }
}

///|
pub fn release_checklist(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> Array[ReleaseItem] {
  let audit = project_audit(moon_mod, readme, paths, sources, policy)
  [
    release_item(
      "moon.mod has package name",
      audit.package_name != "unknown",
      audit.package_name,
    ),
    release_item(
      "moon.mod has valid license",
      audit.package_license != "" && is_valid(audit.package_license),
      audit.package_license,
    ),
    release_item(
      "README mentions license",
      audit.readme_ok,
      if audit.readme_ok {
        "ok"
      } else {
        "missing"
      },
    ),
    release_item(
      "all source files have SPDX headers",
      audit.missing_headers == 0,
      audit.missing_headers.to_string() + " missing",
    ),
    release_item(
      "all SPDX headers are valid",
      audit.invalid_headers == 0,
      audit.invalid_headers.to_string() + " invalid",
    ),
    release_item(
      "policy allows declared licenses",
      audit.policy_errors.is_empty(),
      audit.policy_errors.length().to_string() + " errors",
    ),
  ]
}

///|
pub fn release_ready(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> Bool {
  for item in release_checklist(moon_mod, readme, paths, sources, policy) {
    if !item.passed {
      return false
    }
  }
  true
}

///|
pub fn release_checklist_report(items : Array[ReleaseItem]) -> String {
  let rows : Array[String] = []
  for item in items {
    rows.push(check_mark(item.passed) + " " + item.name + " - " + item.detail)
  }
  join_lines(rows)
}

///|
pub fn check_mark(passed : Bool) -> String {
  if passed {
    "[x]"
  } else {
    "[ ]"
  }
}

///|
pub fn release_report(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> String {
  release_checklist_report(
    release_checklist(moon_mod, readme, paths, sources, policy),
  )
}
