# moonbit-license-audit

`moonbit-license-audit` is a small MoonBit library for auditing project license
metadata. It checks `moon.mod` license declarations, source-file
`SPDX-License-Identifier` headers, and SPDX expressions such as
`MIT OR Apache-2.0` or `GPL-2.0-only WITH Classpath-exception-2.0`.

## Features

- extract SPDX identifiers from line or block comments, validate them, and flag conflicting declarations
- audit `moon.mod` license declarations against README text
- tokenize and parse SPDX license expressions
- support `AND`, `OR`, parentheses, and `WITH` exceptions
- normalize common license and exception identifiers
- use a compact built-in SPDX-oriented catalog for common open-source project licenses
- list licenses, exceptions, operators, and expression depth
- validate identifiers against a compact SPDX-oriented catalog
- check expressions against allow/deny policies
- parse simple policy configuration text
- classify licenses by family and review risk
- generate license obligation and notice checklists
- build a source-file license inventory
- validate a small hand-written third-party dependency manifest
- compare findings with a checked-in audit baseline for CI
- produce project audit, release checklist, remediation, and evidence reports
- render text, Markdown, CSV, and tree reports

## Install

```bash
moon add clbbbb/moonbit-license-audit@0.1.0
```

Local development:

```bash
moon check
moon test
moon run cmd/main
```

## Example

```moonbit nocheck
let expr = "MIT OR Apache-2.0"
println(normalize(expr))
println(validation_report(expr))
println(policy_report(expr, permissive_policy()))
println(profile_table(expr))
println(scan_report("main.mbt", "// SPDX-License-Identifier: MIT\n"))
```

SPDX identifiers embedded in ordinary source text are ignored. If a file carries
more than one distinct SPDX identifier, the scanner reports a conflict instead
of silently choosing one.

Project-level audit:

```moonbit nocheck
let moon_mod = "name = \"demo/pkg\"\nlicense = \"MIT\"\nrepository = \"https://example.invalid/demo/pkg\"\nreadme = \"README.mbt.md\"\n"
let readme = "# demo\n\nLicense: MIT\n"
let paths = ["src/a.mbt", "src/b.mbt"]
let sources = [
  "// SPDX-License-Identifier: MIT\n",
  "// SPDX-License-Identifier: Apache-2.0\n",
]
let audit = project_audit(moon_mod, readme, paths, sources, permissive_policy())
println(project_audit_report(audit))
println(remediation_report(audit))
```

## Scope

This library is for engineering checks and metadata tooling. It does not provide
legal advice and does not generate SPDX JSON documents. The catalog is compact
by design; projects can still use the parser and policy layer while extending
identifier coverage later.

## Difference from adjacent work

This project is not a general dependency visualizer, SBOM generator, or package
registry scanner. Its boundary is deliberately smaller: parse and normalize
license expressions, audit MoonBit project metadata, scan source SPDX headers,
validate declared third-party inputs, and produce review-friendly CI evidence.

It also does not aim to be only a standalone SPDX-expression parser. The parser
exists so MoonBit projects can run practical license metadata checks around
`moon.mod`, README files, source headers, allow/deny policies, and release
review notes.

## Data source

The built-in catalog intentionally covers common library licenses and common
exceptions instead of embedding the full SPDX data set. This keeps the package
reviewable and makes the project focus on audit behavior rather than a large
generated table.

## License

MIT
