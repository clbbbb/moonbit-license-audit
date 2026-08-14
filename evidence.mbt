///|
pub struct AuditEvidence {
  project : ProjectAudit
  third_party_errors : Array[String]
  baseline_new : Array[AuditFinding]
  generated_files : Array[String]
} derive(Debug, Eq)

///|
pub fn audit_evidence(
  project : ProjectAudit,
  packages : Array[ThirdPartyPackage],
  current_findings : Array[AuditFinding],
  baseline : Array[AuditFinding],
  policy : Policy,
) -> AuditEvidence {
  {
    project,
    third_party_errors: third_party_errors(packages, policy),
    baseline_new: new_findings(current_findings, baseline),
    generated_files: evidence_file_names(),
  }
}

///|
pub fn evidence_file_names() -> Array[String] {
  [
    "license-audit.txt", "license-audit.md", "third-party-licenses.md", "audit-baseline.txt",
  ]
}

///|
pub fn evidence_passes(evidence : AuditEvidence) -> Bool {
  audit_passes(evidence.project) &&
  evidence.third_party_errors.is_empty() &&
  evidence.baseline_new.is_empty()
}

///|
pub fn evidence_status(evidence : AuditEvidence) -> String {
  if evidence_passes(evidence) {
    "pass"
  } else {
    "fail"
  }
}

///|
pub fn evidence_error_count(evidence : AuditEvidence) -> Int {
  evidence.project.policy_errors.length() +
  evidence.third_party_errors.length() +
  evidence.baseline_new.length()
}

///|
pub fn evidence_warning_count(evidence : AuditEvidence) -> Int {
  evidence.project.warnings.length()
}

///|
pub fn evidence_summary(evidence : AuditEvidence) -> String {
  join_lines([
    "status: " + evidence_status(evidence),
    "grade: " + audit_grade(evidence.project),
    "errors: " + evidence_error_count(evidence).to_string(),
    "warnings: " + evidence_warning_count(evidence).to_string(),
    "artifacts: " + join_with(evidence.generated_files, ","),
  ])
}

///|
pub fn evidence_failures(evidence : AuditEvidence) -> Array[String] {
  let rows : Array[String] = []
  for error in evidence.project.policy_errors {
    rows.push("project: " + error)
  }
  for error in evidence.third_party_errors {
    rows.push("third-party: " + error)
  }
  for finding in evidence.baseline_new {
    rows.push("new finding: " + finding_key(finding))
  }
  rows
}

///|
pub fn evidence_warnings(evidence : AuditEvidence) -> Array[String] {
  evidence.project.warnings
}

///|
pub fn evidence_report(evidence : AuditEvidence) -> String {
  let rows : Array[String] = [
    "MoonBit license audit evidence",
    evidence_summary(evidence),
    "",
    project_audit_report(evidence.project),
    "",
  ]
  push_section(rows, "failures", evidence_failures(evidence))
  push_section(rows, "warnings", evidence_warnings(evidence))
  join_lines(rows)
}

///|
pub fn evidence_markdown(evidence : AuditEvidence) -> String {
  let rows : Array[String] = [
    "# License audit evidence",
    "",
    "- status: " + evidence_status(evidence),
    "- grade: " + audit_grade(evidence.project),
    "- errors: " + evidence_error_count(evidence).to_string(),
    "- warnings: " + evidence_warning_count(evidence).to_string(),
    "",
  ]
  push_markdown_section(rows, "Failures", evidence_failures(evidence))
  push_markdown_section(rows, "Warnings", evidence_warnings(evidence))
  rows.push("## Expected artifacts")
  rows.push("")
  for file in evidence.generated_files {
    rows.push("- " + file)
  }
  rows.push("")
  join_lines(rows)
}

///|
pub fn ci_annotation(evidence : AuditEvidence) -> String {
  if evidence_passes(evidence) {
    "license audit passed: " + audit_grade(evidence.project)
  } else {
    "license audit failed: " +
    evidence_error_count(evidence).to_string() +
    " issue(s)"
  }
}

///|
pub fn ci_should_fail(evidence : AuditEvidence) -> Bool {
  !evidence_passes(evidence)
}

///|
pub fn evidence_for_inputs(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  packages_text : String,
  baseline_text : String,
  policy : Policy,
) -> AuditEvidence {
  let project = project_audit(moon_mod, readme, paths, sources, policy)
  let findings = findings_from_sources(paths, sources, policy)
  audit_evidence(
    project,
    parse_third_party_manifest(packages_text),
    findings,
    parse_baseline(baseline_text),
    policy,
  )
}

///|
pub fn evidence_inputs_report(
  moon_mod : String,
  readme : String,
  paths : Array[String],
  sources : Array[String],
  packages_text : String,
  baseline_text : String,
  policy : Policy,
) -> String {
  evidence_report(
    evidence_for_inputs(
      moon_mod, readme, paths, sources, packages_text, baseline_text, policy,
    ),
  )
}
