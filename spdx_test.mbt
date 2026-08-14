// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
test "tokenize expression" {
  debug_inspect(
    tokens_report("MIT OR Apache-2.0"),
    content="\"MIT@0\\nOR@4\\nApache-2.0@7\"",
  )
}

///|
test "parse and normalize simple expression" {
  debug_inspect(normalize("mit OR apache-2.0"), content="\"MIT OR Apache-2.0\"")
  debug_inspect(
    parse_tree("MIT AND (Apache-2.0 OR BSD-3-Clause)"),
    content="\"And(License(MIT),Or(License(Apache-2.0),License(BSD-3-Clause)))\"",
  )
}

///|
test "parse exceptions" {
  debug_inspect(
    normalize("GPL-2.0-only WITH Classpath-exception-2.0"),
    content="\"GPL-2.0-only WITH Classpath-exception-2.0\"",
  )
  debug_inspect(
    expression_stats("MIT OR GPL-2.0-only WITH Classpath-exception-2.0"),
    content="\"licenses=2\\nexceptions=1\\noperators=2\\ndepth=2\"",
  )
}

///|
test "validate catalog ids" {
  debug_inspect(
    validation_report("MIT OR Unknown-1.0"),
    content="\"unknown license: Unknown-1.0\"",
  )
  debug_inspect(is_valid("MIT OR Apache-2.0"), content="true")
}

///|
test "policy checks permissive licenses" {
  debug_inspect(
    policy_report("MIT OR Apache-2.0", permissive_policy()),
    content="\"ok\"",
  )
  debug_inspect(
    policy_allows("MIT OR GPL-3.0-only", permissive_policy()),
    content="true",
  )
  debug_inspect(
    policy_allows("GPL-3.0-only", permissive_policy()),
    content="false",
  )
}

///|
test "policy explains alternative license choices" {
  let expression = "MIT OR (GPL-3.0-only AND Apache-2.0)"
  debug_inspect(
    allowed_policy_options(expression, permissive_policy()),
    content="[\"MIT\"]",
  )
  debug_inspect(
    policy_option_report(expression, permissive_policy()),
    content="\"options:\\n[x] MIT\\n[ ] GPL-3.0-only AND Apache-2.0 - license not allowed: GPL-3.0-only; copyleft license not allowed: GPL-3.0-only\"",
  )
}

///|
test "reports summarize expression" {
  debug_inspect(summary("MIT").has_prefix("normalized=MIT"), content="true")
  debug_inspect(
    markdown_report("MIT").find("SPDX expression report") is Some(_),
    content="true",
  )
  debug_inspect(
    csv_report("MIT OR Apache-2.0"),
    content="\"kind,value\\nlicense,MIT\\nlicense,Apache-2.0\"",
  )
}

///|
test "classify license risk" {
  debug_inspect(license_family("MIT"), content="\"permissive\"")
  debug_inspect(license_risk("GPL-3.0-only"), content="\"high\"")
  debug_inspect(highest_risk("MIT OR MPL-2.0"), content="\"medium\"")
  debug_inspect(
    profile_table("MIT OR GPL-3.0-only"),
    content="\"license,family,osi,copyleft,risk\\nMIT,permissive,true,false,low\\nGPL-3.0-only,strong-copyleft,true,true,high\"",
  )
}

///|
test "diagnostics suggest known ids" {
  debug_inspect(
    diagnostics_report("Apache"),
    content="\"error: unknown license: Apache (did you mean Apache-2.0?)\"",
  )
  debug_inspect(quick_fix("mit OR apache-2.0"), content="\"MIT OR Apache-2.0\"")
}

///|
test "scan source license headers" {
  let source = "// SPDX-License-Identifier: MIT\npub fn demo() -> Int { 1 }"
  debug_inspect(scan_report("demo.mbt", source), content="\"demo.mbt: ok MIT\"")
  debug_inspect(
    scan_report("missing.mbt", "pub fn demo() -> Int { 1 }"),
    content="\"missing.mbt: missing SPDX-License-Identifier\"",
  )
}

///|
test "scan ignores SPDX text outside comments" {
  let source = "let marker = \"SPDX-License-Identifier: MIT\"\n"
  debug_inspect(
    scan_report("string.mbt", source),
    content="\"string.mbt: missing SPDX-License-Identifier\"",
  )
}

///|
test "scan accepts block comments and rejects conflicts" {
  let block = "/* SPDX-License-Identifier: Apache-2.0 */\n"
  debug_inspect(
    scan_report("block.mbt", block),
    content="\"block.mbt: ok Apache-2.0\"",
  )
  let conflict = "// SPDX-License-Identifier: MIT\n// SPDX-License-Identifier: Apache-2.0\n"
  debug_inspect(
    scan_report("conflict.mbt", conflict),
    content="\"conflict.mbt: conflicting SPDX-License-Identifier values\"",
  )
}

///|
test "scan SPDX copyright text" {
  let source = "// SPDX-FileCopyrightText: 2026 Example Contributors\n/* SPDX-FileCopyrightText: 2025 Demo Org */\n"
  debug_inspect(
    copyright_report("copyright.mbt", source),
    content="\"copyright.mbt: 2026 Example Contributors; 2025 Demo Org\"",
  )
  debug_inspect(
    missing_copyright_count(["a.mbt", "b.mbt"], [
      source, "let text = \"SPDX-FileCopyrightText: ignored\"",
    ]),
    content="1",
  )
}

///|
test "scan multiple source files" {
  let paths = ["a.mbt", "b.mbt", "c.mbt"]
  let sources = [
    "// SPDX-License-Identifier: MIT\n", "// SPDX-License-Identifier: Unknown-1.0\n",
    "pub fn c() -> Unit { () }",
  ]
  debug_inspect(missing_spdx_count(paths, sources), content="1")
  debug_inspect(invalid_spdx_count(paths, sources), content="1")
}

///|
test "compatibility review levels" {
  debug_inspect(compatibility_report("MIT OR Apache-2.0"), content="\"ok\"")
  debug_inspect(
    compatibility_report("Apache-2.0 AND GPL-2.0-only"),
    content="\"Apache-2.0 is not normally compatible with GPL-2.0-only\"",
  )
  debug_inspect(review_level("GPL-3.0-only"), content="\"legal-review\"")
}

///|
test "moon.mod package audit" {
  let mod_text = "name = \"clbbbb/moonbit-license-audit\"\nlicense = \"MIT\"\nrepository = \"https://github.com/clbbbb/moonbit-license-audit\"\nreadme = \"README.mbt.md\"\n"
  let readme = "# package\n\nLicense: MIT\n"
  debug_inspect(extract_moon_mod_license(mod_text), content="Some(\"MIT\")")
  debug_inspect(
    moon_mod_metadata_report(mod_text),
    content="\"name: clbbbb/moonbit-license-audit\\nlicense: MIT\\nrepository: ok\\nreadme: ok\"",
  )
  debug_inspect(
    package_audit_report(mod_text, readme),
    content="\"moon.mod license: ok MIT\\nREADME license mention: ok\\nreview level: fast-path\"",
  )
}

///|
test "simplify and explain expressions" {
  debug_inspect(simplify_text("mit OR MIT"), content="\"MIT\"")
  debug_inspect(expression_shape("MIT OR Apache-2.0"), content="\"any-of\"")
  debug_inspect(choice_count("MIT OR Apache-2.0"), content="2")
  debug_inspect(requirement_count("MIT AND Apache-2.0"), content="2")
  debug_inspect(
    explain_expression("MIT OR Apache-2.0").has_prefix(
      "normalized: MIT OR Apache-2.0",
    ),
    content="true",
  )
}

///|
test "project audit and release checklist" {
  let mod_text = "name = \"demo/pkg\"\nlicense = \"MIT\"\nrepository = \"https://example.invalid/demo/pkg\"\nreadme = \"README.mbt.md\"\n"
  let readme = "# demo\n\nLicense: MIT\n"
  let paths = ["src/a.mbt", "src/b.mbt"]
  let sources = [
    "// SPDX-License-Identifier: MIT\npub fn a() -> Int { 1 }", "// SPDX-License-Identifier: Apache-2.0\npub fn b() -> Int { 2 }",
  ]
  let audit = project_audit(
    mod_text,
    readme,
    paths,
    sources,
    permissive_policy(),
  )
  debug_inspect(audit_passes(audit), content="true")
  debug_inspect(audit_grade(audit), content="\"A\"")
  debug_inspect(
    join_lines(audit.warnings),
    content="\"source headers include additional licenses: MIT,Apache-2.0\"",
  )
  debug_inspect(
    release_ready(mod_text, readme, paths, sources, permissive_policy()),
    content="true",
  )
  debug_inspect(
    release_report(mod_text, readme, paths, sources, permissive_policy()).find(
      "all source files have SPDX headers",
    )
    is Some(_),
    content="true",
  )
}

///|
test "obligations and notice checklist" {
  debug_inspect(
    obligations_report("Apache-2.0").find("Preserve NOTICE information")
    is Some(_),
    content="true",
  )
  debug_inspect(
    notice_checklist_report("MIT OR Apache-2.0").find(
      "Keep copyright and license notice",
    )
    is Some(_),
    content="true",
  )
}

///|
test "inventory groups source licenses" {
  let paths = ["src/a.mbt", "src/b.mbt", "src/c.mbt"]
  let sources = [
    "// SPDX-License-Identifier: MIT\n", "// SPDX-License-Identifier: Apache-2.0\n",
    "// SPDX-License-Identifier: MIT\n",
  ]
  let inventory = build_inventory(paths, sources)
  debug_inspect(dominant_license(inventory), content="\"MIT\"")
  debug_inspect(
    inventory_report(inventory),
    content="\"MIT: src/a.mbt,src/c.mbt\\nApache-2.0: src/b.mbt\"",
  )
  debug_inspect(
    mixed_license_warning(inventory, "MIT"),
    content="\"source headers include additional licenses: MIT,Apache-2.0\"",
  )
}

///|
test "policy config parses simple text" {
  let config = "allow = MIT, Apache-2.0\nallow_copyleft = false\nrequire_osi = true\n"
  let policy = parse_policy_config(config)
  debug_inspect(
    policy_config_report(policy),
    content="\"allowed=MIT,Apache-2.0\\ndenied=\\nallow_copyleft=false\\nrequire_osi=true\"",
  )
  debug_inspect(policy_allows("MIT OR GPL-3.0-only", policy), content="true")
}

///|
test "remediation suggests fixes" {
  let mod_text = "name = \"demo/pkg\"\nlicense = \"GPL-3.0-only\"\n"
  let readme = "# demo\n"
  let audit = project_audit(
    mod_text,
    readme,
    ["src/a.mbt"],
    ["pub fn a() -> Int { 1 }"],
    permissive_policy(),
  )
  debug_inspect(
    remediation_report(audit).find("source files") is Some(_),
    content="true",
  )
  debug_inspect(
    remediation_markdown(audit).has_prefix("# Remediation plan"),
    content="true",
  )
}

///|
test "audit README completeness" {
  let readme = "# Demo\n\n## Install\nmoon add demo/pkg\n\n## Usage\nA short command line example.\n\n## License\nMIT\n"
  let audit = audit_readme(readme)
  debug_inspect(audit.has_title, content="true")
  debug_inspect(audit.has_example, content="false")
  debug_inspect(readme_matches_package_license(readme, "MIT"), content="true")
  debug_inspect(readme_audit_warnings(audit).length(), content="1")
}

///|
test "filter paths with file rules" {
  let paths = ["src/a.mbt", "_build/a.mbt", "README.md", "vendor/x.mbt"]
  let filtered = filter_sources_by_rule(paths, ["a", "b", "c", "d"])
  debug_inspect(filtered.0, content="[\"src/a.mbt\", \"vendor/x.mbt\"]")
  debug_inspect(classify_path("README.md").kind, content="\"documentation\"")
  debug_inspect(
    ignored_paths_report(paths).find("_build/a.mbt") is Some(_),
    content="true",
  )
}

///|
test "workspace audit combines project and README checks" {
  let mod_text = "name = \"demo/pkg\"\nlicense = \"MIT\"\nrepository = \"https://example.invalid/demo/pkg\"\nreadme = \"README.md\"\n"
  let readme = "# Demo\n\n## Install\nmoon add demo/pkg\n\n## Usage\nExample text.\n\n## License\nMIT\n"
  let paths = ["src/a.mbt", "_build/generated.mbt"]
  let sources = [
    "// SPDX-License-Identifier: MIT\npub fn a() -> Int { 1 }", "ignored",
  ]
  let audit = workspace_audit(
    mod_text,
    readme,
    paths,
    sources,
    permissive_policy(),
  )
  debug_inspect(workspace_grade(audit, permissive_policy()), content="\"A\"")
  debug_inspect(audit.ignored_paths, content="[\"_build/generated.mbt\"]")
  debug_inspect(
    workspace_report(audit, permissive_policy()).find("workspace grade")
    is Some(_),
    content="true",
  )
}

///|
test "matrix highlights incompatible license pairs" {
  let cells = compatibility_matrix(["MIT", "Apache-2.0", "GPL-2.0-only"])
  debug_inspect(incompatible_pairs(cells).length(), content="2")
  debug_inspect(
    compatibility_summary(cells),
    content="\"2 license pair(s) need review\"",
  )
}

///|
test "third party manifest is policy checked" {
  let text = "name = \"tiny-lib\"\nlicense = \"MIT\"\nsource = \"https://example.invalid/tiny-lib\"\nnotice = true\n\nname = \"copyleft-lib\"\nlicense = \"GPL-3.0-only\"\nsource = \"https://example.invalid/copyleft\"\nnotice = true\n"
  let packages = parse_third_party_manifest(text)
  debug_inspect(packages.length(), content="2")
  debug_inspect(
    third_party_errors(packages, permissive_policy()).length(),
    content="2",
  )
  debug_inspect(
    third_party_risk_summary(packages).find("high: copyleft-lib") is Some(_),
    content="true",
  )
}

///|
test "third party manifest reports malformed records" {
  let text = "name = \"tiny-lib\"\nlicense = \"MIT\"\nnotice = maybe\nextra = \"value\"\n"
  let errors = third_party_manifest_errors(text)
  debug_inspect(
    join_lines(errors),
    content="\"line 3: notice must be true or false\\nline 4: unknown field extra\\nrecord starting at line 1: source is missing\"",
  )
  debug_inspect(third_party_manifest_valid(text), content="false")
}

///|
test "baseline only fails newly introduced findings" {
  let old = [
    audit_finding("src/a.mbt", "missing-spdx", "SPDX header is missing"),
  ]
  let current = old +
    [audit_finding("src/b.mbt", "policy", "GPL-3.0-only is not allowed")]
  let loaded = parse_baseline(serialize_baseline(old))
  debug_inspect(new_findings(current, loaded).length(), content="1")
  debug_inspect(resolved_findings(old, current).length(), content="1")
  debug_inspect(baseline_passes(old, loaded), content="true")
}

///|
test "evidence combines audit gates" {
  let project = project_audit(
    "name = \"demo/pkg\"\nlicense = \"MIT\"\nrepository = \"https://example.invalid/demo\"\n",
    "# Demo\n\nLicense: MIT\n",
    ["src/a.mbt"],
    ["// SPDX-License-Identifier: MIT\n"],
    permissive_policy(),
  )
  let evidence = audit_evidence(project, [], [], [], permissive_policy())
  debug_inspect(evidence_passes(evidence), content="true")
  debug_inspect(ci_annotation(evidence), content="\"license audit passed: A\"")
}
