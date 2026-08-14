///|
pub struct LicenseUse {
  path : String
  expression : String
  licenses : Array[String]
  valid : Bool
} derive(Debug, Eq)

///|
pub fn license_use(
  path : String,
  expression : String,
  licenses : Array[String],
  valid : Bool,
) -> LicenseUse {
  { path, expression, licenses, valid }
}

///|
pub fn build_inventory(
  paths : Array[String],
  sources : Array[String],
) -> Array[LicenseUse] {
  inventory_from_source_results(scan_sources(paths, sources))
}

///|
pub fn inventory_from_source_results(
  results : Array[SourceLicense],
) -> Array[LicenseUse] {
  let rows : Array[LicenseUse] = []
  for item in results {
    if item.found && item.valid {
      match parse(item.expression).expr {
        Some(expr) =>
          rows.push(
            license_use(item.path, item.expression, licenses(expr), true),
          )
        None => rows.push(license_use(item.path, item.expression, [], false))
      }
    } else {
      rows.push(license_use(item.path, item.expression, [], false))
    }
  }
  rows
}

///|
pub fn inventory_licenses(inventory : Array[LicenseUse]) -> Array[String] {
  let rows : Array[String] = []
  for item in inventory {
    for id in item.licenses {
      rows.push(id)
    }
  }
  unique_strings(rows)
}

///|
pub fn files_using_license(
  inventory : Array[LicenseUse],
  id : String,
) -> Array[String] {
  let target = canonical_license(id)
  let rows : Array[String] = []
  for item in inventory {
    if contains_string(item.licenses, target) {
      rows.push(item.path)
    }
  }
  rows
}

///|
pub fn inventory_report(inventory : Array[LicenseUse]) -> String {
  let rows : Array[String] = []
  for id in inventory_licenses(inventory) {
    rows.push(id + ": " + join_with(files_using_license(inventory, id), ","))
  }
  if rows.is_empty() {
    "no valid license headers"
  } else {
    join_lines(rows)
  }
}

///|
pub fn inventory_policy_errors(
  inventory : Array[LicenseUse],
  policy : Policy,
) -> Array[String] {
  let rows : Array[String] = []
  for item in inventory {
    if !item.valid {
      rows.push(item.path + ": invalid or missing SPDX header")
    } else {
      for error in policy_errors(item.expression, policy) {
        rows.push(item.path + ": " + error)
      }
    }
  }
  rows
}

///|
pub fn inventory_policy_report(
  inventory : Array[LicenseUse],
  policy : Policy,
) -> String {
  let rows = inventory_policy_errors(inventory, policy)
  if rows.is_empty() {
    "ok"
  } else {
    join_lines(rows)
  }
}

///|
pub fn dominant_license(inventory : Array[LicenseUse]) -> String {
  let ids = inventory_licenses(inventory)
  let mut best = ""
  let mut best_count = 0
  for id in ids {
    let count = files_using_license(inventory, id).length()
    if count > best_count {
      best = id
      best_count = count
    }
  }
  best
}

///|
pub fn mixed_license_warning(
  inventory : Array[LicenseUse],
  package_license : String,
) -> String {
  let package_id = canonical_license(package_license)
  let ids = inventory_licenses(inventory)
  if ids.is_empty() {
    "no valid source license headers"
  } else if ids.length() == 1 && contains_string(ids, package_id) {
    "source headers match package license"
  } else if contains_string(ids, package_id) {
    "source headers include additional licenses: " + join_with(ids, ",")
  } else {
    "source headers do not include package license " +
    package_id +
    ": " +
    join_with(ids, ",")
  }
}

///|
pub fn inventory_markdown(inventory : Array[LicenseUse]) -> String {
  let rows : Array[String] = ["# License inventory", ""]
  for id in inventory_licenses(inventory) {
    rows.push("## " + id)
    rows.push("")
    for path in files_using_license(inventory, id) {
      rows.push("- `" + path + "`")
    }
    rows.push("")
  }
  if rows.length() == 2 {
    rows.push("- no valid license headers")
  }
  join_lines(rows)
}
