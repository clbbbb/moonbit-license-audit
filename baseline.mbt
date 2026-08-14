// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub struct AuditFinding {
  path : String
  kind : String
  detail : String
} derive(Debug, Eq)

///|
pub fn audit_finding(
  path : String,
  kind : String,
  detail : String,
) -> AuditFinding {
  { path, kind, detail }
}

///|
pub fn finding_key(finding : AuditFinding) -> String {
  finding.path + "|" + finding.kind + "|" + finding.detail
}

///|
pub fn findings_from_sources(
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
) -> Array[AuditFinding] {
  let rows : Array[AuditFinding] = []
  for item in scan_sources(paths, sources) {
    if !item.found {
      rows.push(
        audit_finding(item.path, "missing-spdx", "SPDX header is missing"),
      )
    } else if !item.valid {
      rows.push(audit_finding(item.path, "invalid-spdx", item.message))
    } else {
      for error in policy_errors(item.expression, policy) {
        rows.push(audit_finding(item.path, "policy", error))
      }
    }
  }
  rows
}

///|
pub fn findings_from_project(audit : ProjectAudit) -> Array[AuditFinding] {
  let rows : Array[AuditFinding] = []
  for error in audit.policy_errors {
    rows.push(audit_finding("moon.mod", "policy", error))
  }
  for warning in audit.warnings {
    rows.push(audit_finding("project", "warning", warning))
  }
  rows
}

///|
pub fn serialize_baseline(findings : Array[AuditFinding]) -> String {
  let rows : Array[String] = [
    "# moonbit-license-audit baseline", "# path|kind|detail",
  ]
  for finding in findings {
    rows.push(finding_key(finding))
  }
  join_lines(rows)
}

///|
pub fn parse_baseline(text : String) -> Array[AuditFinding] {
  let rows : Array[AuditFinding] = []
  for raw in split_char(text, '\n') {
    let line = trim_ascii(raw)
    if line != "" && !line.has_prefix("#") {
      match parse_baseline_line(line) {
        Some(finding) => rows.push(finding)
        None => ()
      }
    }
  }
  rows
}

///|
pub fn parse_baseline_line(line : String) -> AuditFinding? {
  let parts = split_char(line, '|')
  if parts.length() < 3 {
    None
  } else {
    let path = trim_ascii(parts[0])
    let kind = trim_ascii(parts[1])
    let detail = join_tail(parts, 2, "|")
    if path == "" || kind == "" || detail == "" {
      None
    } else {
      Some(audit_finding(path, kind, detail))
    }
  }
}

///|
pub fn join_tail(
  parts : Array[String],
  start : Int,
  separator : String,
) -> String {
  let rows : Array[String] = []
  for index = start; index < parts.length(); index = index + 1 {
    rows.push(parts[index])
  }
  join_with(rows, separator)
}

///|
pub fn finding_in(
  findings : Array[AuditFinding],
  target : AuditFinding,
) -> Bool {
  for finding in findings {
    if finding_key(finding) == finding_key(target) {
      return true
    }
  }
  false
}

///|
pub fn new_findings(
  current : Array[AuditFinding],
  baseline : Array[AuditFinding],
) -> Array[AuditFinding] {
  let rows : Array[AuditFinding] = []
  for finding in current {
    if !finding_in(baseline, finding) {
      rows.push(finding)
    }
  }
  rows
}

///|
pub fn resolved_findings(
  current : Array[AuditFinding],
  baseline : Array[AuditFinding],
) -> Array[AuditFinding] {
  let rows : Array[AuditFinding] = []
  for finding in baseline {
    if !finding_in(current, finding) {
      rows.push(finding)
    }
  }
  rows
}

///|
pub fn unchanged_findings(
  current : Array[AuditFinding],
  baseline : Array[AuditFinding],
) -> Array[AuditFinding] {
  let rows : Array[AuditFinding] = []
  for finding in current {
    if finding_in(baseline, finding) {
      rows.push(finding)
    }
  }
  rows
}

///|
pub fn baseline_passes(
  current : Array[AuditFinding],
  baseline : Array[AuditFinding],
) -> Bool {
  new_findings(current, baseline).is_empty()
}

///|
pub fn findings_lines(findings : Array[AuditFinding]) -> Array[String] {
  let rows : Array[String] = []
  for finding in findings {
    rows.push(finding.path + ": [" + finding.kind + "] " + finding.detail)
  }
  rows
}

///|
pub fn baseline_report(
  current : Array[AuditFinding],
  baseline : Array[AuditFinding],
) -> String {
  let added = new_findings(current, baseline)
  let fixed = resolved_findings(current, baseline)
  let unchanged = unchanged_findings(current, baseline)
  let rows : Array[String] = [
    "new findings: " + added.length().to_string(),
    "resolved findings: " + fixed.length().to_string(),
    "unchanged findings: " + unchanged.length().to_string(),
  ]
  push_section(rows, "new findings", findings_lines(added))
  push_section(rows, "resolved findings", findings_lines(fixed))
  join_lines(rows)
}

///|
pub fn baseline_markdown(
  current : Array[AuditFinding],
  baseline : Array[AuditFinding],
) -> String {
  let rows : Array[String] = [
    "# Audit baseline comparison",
    "",
    "- new findings: " + new_findings(current, baseline).length().to_string(),
    "- resolved findings: " +
    resolved_findings(current, baseline).length().to_string(),
    "- unchanged findings: " +
    unchanged_findings(current, baseline).length().to_string(),
    "",
  ]
  push_markdown_section(
    rows,
    "New findings",
    findings_lines(new_findings(current, baseline)),
  )
  push_markdown_section(
    rows,
    "Resolved findings",
    findings_lines(resolved_findings(current, baseline)),
  )
  join_lines(rows)
}

///|
pub fn audit_baseline_report(
  paths : Array[String],
  sources : Array[String],
  policy : Policy,
  baseline_text : String,
) -> String {
  baseline_report(
    findings_from_sources(paths, sources, policy),
    parse_baseline(baseline_text),
  )
}
