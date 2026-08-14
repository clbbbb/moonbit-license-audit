///|
pub struct FixSuggestion {
  target : String
  severity : String
  action : String
} derive(Debug, Eq)

///|
pub fn fix_suggestion(
  target : String,
  severity : String,
  action : String,
) -> FixSuggestion {
  { target, severity, action }
}

///|
pub fn suggestions_for_audit(audit : ProjectAudit) -> Array[FixSuggestion] {
  let rows : Array[FixSuggestion] = []
  if audit.package_license == "" {
    rows.push(
      fix_suggestion("moon.mod", "high", "add an OSI-approved license field"),
    )
  }
  if !audit.readme_ok {
    rows.push(
      fix_suggestion("README", "medium", "mention the declared project license"),
    )
  }
  if audit.missing_headers > 0 {
    rows.push(
      fix_suggestion(
        "source files", "medium", "add SPDX-License-Identifier headers to files missing license metadata",
      ),
    )
  }
  if audit.invalid_headers > 0 {
    rows.push(
      fix_suggestion(
        "source files", "high", "fix invalid SPDX expressions before release",
      ),
    )
  }
  for error in audit.policy_errors {
    rows.push(
      fix_suggestion(
        "policy",
        severity_for_error(error),
        action_for_error(error),
      ),
    )
  }
  rows
}

///|
pub fn severity_for_error(error : String) -> String {
  let lower = lower_ascii(error)
  if lower.find("unknown") is Some(_) || lower.find("denied") is Some(_) {
    "high"
  } else if lower.find("copyleft") is Some(_) {
    "high"
  } else if lower.find("not allowed") is Some(_) {
    "medium"
  } else {
    "medium"
  }
}

///|
pub fn action_for_error(error : String) -> String {
  let lower = lower_ascii(error)
  if lower.find("unknown") is Some(_) {
    "replace unknown license IDs with canonical SPDX IDs"
  } else if lower.find("denied") is Some(_) {
    "remove denied license or update policy with explicit approval"
  } else if lower.find("copyleft") is Some(_) {
    "review copyleft obligations and switch policy mode only if acceptable"
  } else if lower.find("not allowed") is Some(_) {
    "choose an allowed license alternative or update the allow list"
  } else {
    "review the reported license issue"
  }
}

///|
pub fn remediation_report(audit : ProjectAudit) -> String {
  let rows : Array[String] = []
  for item in suggestions_for_audit(audit) {
    rows.push(item.severity + ": " + item.target + " - " + item.action)
  }
  if rows.is_empty() {
    "no remediation needed"
  } else {
    join_lines(rows)
  }
}

///|
pub fn remediation_markdown(audit : ProjectAudit) -> String {
  let rows : Array[String] = ["# Remediation plan", ""]
  let suggestions = suggestions_for_audit(audit)
  if suggestions.is_empty() {
    rows.push("- no remediation needed")
  } else {
    for item in suggestions {
      rows.push("- `" + item.severity + "` " + item.target + ": " + item.action)
    }
  }
  join_lines(rows)
}

///|
pub fn audit_bundle_report(audit : ProjectAudit) -> String {
  join_lines([project_audit_report(audit), "", remediation_report(audit)])
}
