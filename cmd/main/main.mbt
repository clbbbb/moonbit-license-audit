///|
fn main {
  let expr = "MIT OR Apache-2.0"
  let source = "// SPDX-License-Identifier: MIT\npub fn demo() -> Int { 1 }"
  let moon_mod = "name = \"demo/pkg\"\nlicense = \"MIT\"\nrepository = \"https://example.invalid/demo/pkg\"\nreadme = \"README.mbt.md\"\n"
  let readme = "# demo\n\nLicense: MIT\n"
  let paths = ["src/a.mbt", "src/b.mbt"]
  let sources = [
    "// SPDX-License-Identifier: MIT\n", "// SPDX-License-Identifier: Apache-2.0\n",
  ]
  let audit = @audit.project_audit(
    moon_mod,
    readme,
    paths,
    sources,
    @audit.permissive_policy(),
  )
  println("moonbit-license-audit demo")
  println(@audit.summary(expr))
  println(@audit.policy_report(expr, @audit.permissive_policy()))
  println(@audit.profile_table(expr))
  println(@audit.scan_report("demo.mbt", source))
  println(@audit.project_audit_report(audit))
  println(@audit.remediation_report(audit))
}
