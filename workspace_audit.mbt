///|
pub struct WorkspaceAudit {
  project : ProjectAudit
  readme : ReadmeAudit
  inventory : Array[LicenseUse]
  ignored_paths : Array[String]
} derive(Debug, Eq)

///|
pub fn workspace_audit(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> WorkspaceAudit {
  let filtered = filter_sources_by_rule(paths, sources)
  let scan_paths = filtered.0
  let scan_sources = filtered.1
  {
    project: project_audit(moon_mod, readme, scan_paths, scan_sources, policy),
    readme: audit_readme(readme),
    inventory: build_inventory(scan_paths, scan_sources),
    ignored_paths: ignored_paths(paths),
  }
}

///|
pub fn ignored_paths(paths : Array[String]) -> Array[String] {
  let rows : Array[String] = []
  for path in paths {
    if !should_scan_path(path) {
      rows.push(path)
    }
  }
  rows
}

///|
pub fn workspace_warnings(audit : WorkspaceAudit) -> Array[String] {
  unique_strings(audit.project.warnings + readme_audit_warnings(audit.readme))
}

///|
pub fn workspace_errors(
  audit : WorkspaceAudit,
  policy : Policy,
) -> Array[String] {
  unique_strings(
    audit.project.policy_errors +
    inventory_policy_errors(audit.inventory, policy),
  )
}

///|
pub fn workspace_score(audit : WorkspaceAudit, policy : Policy) -> Int {
  let mut score = audit_score(audit.project)
  score = score - readme_audit_warnings(audit.readme).length() * 3
  score = score - inventory_policy_errors(audit.inventory, policy).length() * 8
  if score < 0 {
    0
  } else {
    score
  }
}

///|
pub fn workspace_grade(audit : WorkspaceAudit, policy : Policy) -> String {
  let score = workspace_score(audit, policy)
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
pub fn workspace_report(audit : WorkspaceAudit, policy : Policy) -> String {
  let rows : Array[String] = [
    "workspace grade: " + workspace_grade(audit, policy),
    "workspace score: " + workspace_score(audit, policy).to_string(),
    "",
    project_audit_report(audit.project),
    "",
    readme_audit_report_from_audit(audit.readme),
    "",
    inventory_report(audit.inventory),
  ]
  if !audit.ignored_paths.is_empty() {
    rows.push("")
    rows.push("ignored paths: " + join_with(audit.ignored_paths, ","))
  }
  join_lines(rows)
}

///|
pub fn readme_audit_report_from_audit(audit : ReadmeAudit) -> String {
  let rows : Array[String] = [
    "README title: " + bool_word(audit.has_title),
    "README license: " + bool_word(audit.has_license),
    "README install: " + bool_word(audit.has_install),
    "README usage: " + bool_word(audit.has_usage),
    "README example: " + bool_word(audit.has_example),
  ]
  push_section(rows, "README warnings", readme_audit_warnings(audit))
  join_lines(rows)
}

///|
pub fn audit_workspace_report(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> String {
  workspace_report(
    workspace_audit(moon_mod, readme, paths, sources, policy),
    policy,
  )
}
