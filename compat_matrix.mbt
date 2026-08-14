///|
pub struct CompatibilityCell {
  left : String
  right : String
  compatible : Bool
  reason : String
} derive(Debug, Eq)

///|
pub fn compatibility_cell(
  left : String,
  right : String,
  compatible : Bool,
  reason : String,
) -> CompatibilityCell {
  { left, right, compatible, reason }
}

///|
pub fn license_pair_compatibility(
  left : String,
  right : String,
) -> CompatibilityCell {
  let a = canonical_license(left)
  let b = canonical_license(right)
  if a == b {
    compatibility_cell(a, b, true, "same license")
  } else if !is_known_license(a) || !is_known_license(b) {
    compatibility_cell(a, b, false, "unknown license requires manual review")
  } else if (a == "Apache-2.0" && b == "GPL-2.0-only") ||
    (b == "Apache-2.0" && a == "GPL-2.0-only") {
    compatibility_cell(
      a, b, false, "Apache-2.0 and GPL-2.0-only are usually incompatible",
    )
  } else if (a == "CDDL-1.0" && license_family(b) == "strong-copyleft") ||
    (b == "CDDL-1.0" && license_family(a) == "strong-copyleft") {
    compatibility_cell(
      a, b, false, "CDDL with GPL-style copyleft needs legal review",
    )
  } else if license_risk(a) == "high" || license_risk(b) == "high" {
    compatibility_cell(a, b, false, "strong copyleft combination needs review")
  } else {
    compatibility_cell(a, b, true, "no compact-catalog conflict")
  }
}

///|
pub fn compatibility_matrix(ids : Array[String]) -> Array[CompatibilityCell] {
  let rows : Array[CompatibilityCell] = []
  let unique = unique_strings(ids)
  for i = 0; i < unique.length(); i = i + 1 {
    for j = i; j < unique.length(); j = j + 1 {
      rows.push(license_pair_compatibility(unique[i], unique[j]))
    }
  }
  rows
}

///|
pub fn inventory_compatibility_matrix(
  inventory : Array[LicenseUse],
) -> Array[CompatibilityCell] {
  compatibility_matrix(inventory_licenses(inventory))
}

///|
pub fn compatibility_matrix_report(cells : Array[CompatibilityCell]) -> String {
  let rows : Array[String] = ["left,right,compatible,reason"]
  for cell in cells {
    rows.push(
      cell.left +
      "," +
      cell.right +
      "," +
      bool_word(cell.compatible) +
      "," +
      cell.reason,
    )
  }
  join_lines(rows)
}

///|
pub fn incompatible_pairs(
  cells : Array[CompatibilityCell],
) -> Array[CompatibilityCell] {
  let rows : Array[CompatibilityCell] = []
  for cell in cells {
    if !cell.compatible {
      rows.push(cell)
    }
  }
  rows
}

///|
pub fn compatibility_summary(cells : Array[CompatibilityCell]) -> String {
  let bad = incompatible_pairs(cells)
  if bad.is_empty() {
    "all checked license pairs are compatible in compact rules"
  } else {
    bad.length().to_string() + " license pair(s) need review"
  }
}
