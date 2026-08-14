///|
pub struct ThirdPartyPackage {
  name : String
  license : String
  source : String
  notice : Bool
} derive(Debug, Eq)

///|
pub fn third_party_package(
  name : String,
  license : String,
  source : String,
  notice : Bool,
) -> ThirdPartyPackage {
  { name, license: normalize(license), source, notice }
}

///|
pub fn parse_third_party_manifest(text : String) -> Array[ThirdPartyPackage] {
  let rows : Array[ThirdPartyPackage] = []
  let mut name = ""
  let mut license = ""
  let mut source = ""
  let mut notice = false
  for line in split_char(text, '\n') {
    let clean = trim_ascii(line)
    if clean == "" {
      add_third_party_if_complete(rows, name, license, source, notice)
      name = ""
      license = ""
      source = ""
      notice = false
    } else if !clean.has_prefix("#") {
      match third_party_field(clean) {
        Some((key, value)) =>
          if key == "name" {
            name = value
          } else if key == "license" {
            license = value
          } else if key == "source" {
            source = value
          } else if key == "notice" {
            notice = parse_bool(value)
          } else {
            ()
          }
        None => ()
      }
    }
  }
  add_third_party_if_complete(rows, name, license, source, notice)
  rows
}

///|
pub fn third_party_manifest_errors(text : String) -> Array[String] {
  let mut errors : Array[String] = []
  let mut name = ""
  let mut license = ""
  let mut source = ""
  let mut record_line = 0
  let mut seen : Array[String] = []
  let lines = split_char(text, '\n')
  for index = 0; index < lines.length(); index = index + 1 {
    let clean = trim_ascii(lines[index])
    if clean == "" {
      errors = errors +
        third_party_record_errors(record_line, name, license, source)
      name = ""
      license = ""
      source = ""
      record_line = 0
      seen = []
    } else if !clean.has_prefix("#") {
      if record_line == 0 {
        record_line = index + 1
      }
      match third_party_field(clean) {
        Some((key, value)) =>
          if !is_third_party_field(key) {
            errors.push(
              "line " + (index + 1).to_string() + ": unknown field " + key,
            )
          } else if contains_string(seen, key) {
            errors.push(
              "line " + (index + 1).to_string() + ": duplicate field " + key,
            )
          } else if key == "notice" && !is_bool_config_value(value) {
            errors.push(
              "line " +
              (index + 1).to_string() +
              ": notice must be true or false",
            )
          } else {
            seen.push(key)
            if key == "name" {
              name = value
            } else if key == "license" {
              license = value
            } else if key == "source" {
              source = value
            } else {
              ()
            }
          }
        None =>
          errors.push(
            "line " + (index + 1).to_string() + ": expected key = value",
          )
      }
    }
  }
  errors + third_party_record_errors(record_line, name, license, source)
}

///|
pub fn is_third_party_field(key : String) -> Bool {
  key == "name" || key == "license" || key == "source" || key == "notice"
}

///|
pub fn is_bool_config_value(value : String) -> Bool {
  let lower = lower_ascii(value)
  lower == "true" || lower == "false"
}

///|
pub fn third_party_record_errors(
  line : Int,
  name : String,
  license : String,
  source : String,
) -> Array[String] {
  let errors : Array[String] = []
  if line > 0 {
    if name == "" {
      errors.push(
        "record starting at line " + line.to_string() + ": name is missing",
      )
    }
    if license == "" {
      errors.push(
        "record starting at line " + line.to_string() + ": license is missing",
      )
    }
    if source == "" {
      errors.push(
        "record starting at line " + line.to_string() + ": source is missing",
      )
    }
  }
  errors
}

///|
pub fn third_party_manifest_valid(text : String) -> Bool {
  third_party_manifest_errors(text).is_empty()
}

///|
pub fn third_party_field(line : String) -> (String, String)? {
  match line.find("=") {
    Some(index) => {
      let key = lower_ascii(
        trim_ascii(line.unsafe_substring(start=0, end=index)),
      )
      let raw = trim_ascii(
        line.unsafe_substring(start=index + 1, end=line.length()),
      )
      Some((key, trim_config_value(raw)))
    }
    None => None
  }
}

///|
pub fn trim_config_value(value : String) -> String {
  match quoted_prefix(value) {
    Some(text) => text
    None => trim_ascii(value)
  }
}

///|
pub fn add_third_party_if_complete(
  rows : Array[ThirdPartyPackage],
  name : String,
  license : String,
  source : String,
  notice : Bool,
) -> Unit {
  if name != "" || license != "" || source != "" {
    rows.push(third_party_package(name, license, source, notice))
  }
}

///|
pub fn third_party_errors(
  packages : Array[ThirdPartyPackage],
  policy : Policy,
) -> Array[String] {
  let rows : Array[String] = []
  for item in packages {
    for error in third_party_package_errors(item, policy) {
      rows.push(item.name + ": " + error)
    }
  }
  duplicate_third_party_errors(packages, rows)
  rows
}

///|
pub fn third_party_package_errors(
  item : ThirdPartyPackage,
  policy : Policy,
) -> Array[String] {
  let rows : Array[String] = []
  if item.name == "" {
    rows.push("name is missing")
  }
  if item.source == "" {
    rows.push("source URL is missing")
  }
  if item.license == "" {
    rows.push("license is missing")
  } else {
    for error in validation_errors(item.license) {
      rows.push(error)
    }
    if is_valid(item.license) {
      for error in policy_errors(item.license, policy) {
        rows.push(error)
      }
    }
  }
  if third_party_needs_notice(item) && !item.notice {
    rows.push("notice acknowledgement is missing")
  }
  rows
}

///|
pub fn duplicate_third_party_errors(
  packages : Array[ThirdPartyPackage],
  rows : Array[String],
) -> Unit {
  for index = 0; index < packages.length(); index = index + 1 {
    let item = packages[index]
    for earlier = 0; earlier < index; earlier = earlier + 1 {
      if lower_ascii(item.name) == lower_ascii(packages[earlier].name) {
        rows.push(item.name + ": duplicate package entry")
        break
      }
    }
  }
}

///|
pub fn third_party_needs_notice(item : ThirdPartyPackage) -> Bool {
  if item.license == "" || !is_valid(item.license) {
    false
  } else {
    let expr = parse_or_panic(item.license)
    for id in licenses(expr) {
      if license_needs_notice(id) {
        return true
      }
    }
    false
  }
}

///|
pub fn license_needs_notice(id : String) -> Bool {
  let license = canonical_license(id)
  license != "CC0-1.0" && license != "Unlicense"
}

///|
pub fn third_party_licenses(
  packages : Array[ThirdPartyPackage],
) -> Array[String] {
  let rows : Array[String] = []
  for item in packages {
    if item.license != "" {
      rows.push(item.license)
    }
  }
  unique_strings(rows)
}

///|
pub fn third_party_without_notice(
  packages : Array[ThirdPartyPackage],
) -> Array[ThirdPartyPackage] {
  let rows : Array[ThirdPartyPackage] = []
  for item in packages {
    if third_party_needs_notice(item) && !item.notice {
      rows.push(item)
    }
  }
  rows
}

///|
pub fn third_party_by_license(
  packages : Array[ThirdPartyPackage],
  license : String,
) -> Array[ThirdPartyPackage] {
  let rows : Array[ThirdPartyPackage] = []
  let target = normalize(license)
  for item in packages {
    if item.license == target {
      rows.push(item)
    }
  }
  rows
}

///|
pub fn third_party_names(packages : Array[ThirdPartyPackage]) -> Array[String] {
  let rows : Array[String] = []
  for item in packages {
    rows.push(item.name)
  }
  rows
}

///|
pub fn third_party_policy_passes(
  packages : Array[ThirdPartyPackage],
  policy : Policy,
) -> Bool {
  third_party_errors(packages, policy).is_empty()
}

///|
pub fn third_party_report(
  packages : Array[ThirdPartyPackage],
  policy : Policy,
) -> String {
  let rows : Array[String] = [
    "third-party packages: " + packages.length().to_string(),
    "licenses: " + join_with(third_party_licenses(packages), ","),
    "notice acknowledgements missing: " +
    third_party_without_notice(packages).length().to_string(),
  ]
  push_section(rows, "third-party errors", third_party_errors(packages, policy))
  join_lines(rows)
}

///|
pub fn third_party_markdown(
  packages : Array[ThirdPartyPackage],
  policy : Policy,
) -> String {
  let rows : Array[String] = [
    "# Third-party license inventory", "", "| Package | License | Source | Notice |",
    "| --- | --- | --- | --- |",
  ]
  for item in packages {
    rows.push(
      "| " +
      item.name +
      " | " +
      item.license +
      " | " +
      item.source +
      " | " +
      bool_word(item.notice) +
      " |",
    )
  }
  rows.push("")
  push_markdown_section(
    rows,
    "Validation errors",
    third_party_errors(packages, policy),
  )
  join_lines(rows)
}

///|
pub fn third_party_license_summary(
  packages : Array[ThirdPartyPackage],
) -> String {
  let rows : Array[String] = []
  for license in third_party_licenses(packages) {
    rows.push(
      license +
      ": " +
      third_party_by_license(packages, license).length().to_string(),
    )
  }
  if rows.is_empty() {
    "no third-party packages"
  } else {
    join_lines(rows)
  }
}

///|
pub fn third_party_sources_missing(
  packages : Array[ThirdPartyPackage],
) -> Array[String] {
  let rows : Array[String] = []
  for item in packages {
    if item.source == "" {
      rows.push(item.name)
    }
  }
  rows
}

///|
pub fn third_party_count_for_license(
  packages : Array[ThirdPartyPackage],
  license : String,
) -> Int {
  third_party_by_license(packages, license).length()
}

///|
pub fn third_party_invalid_licenses(
  packages : Array[ThirdPartyPackage],
) -> Array[String] {
  let rows : Array[String] = []
  for item in packages {
    if item.license == "" || !is_valid(item.license) {
      rows.push(item.name)
    }
  }
  rows
}

///|
pub fn third_party_risk_summary(packages : Array[ThirdPartyPackage]) -> String {
  let low : Array[String] = []
  let medium : Array[String] = []
  let high : Array[String] = []
  let unknown : Array[String] = []
  for item in packages {
    if item.license == "" || !is_valid(item.license) {
      unknown.push(item.name)
    } else {
      match highest_risk(item.license) {
        "low" => low.push(item.name)
        "medium" => medium.push(item.name)
        "high" => high.push(item.name)
        _ => unknown.push(item.name)
      }
    }
  }
  join_lines([
    "low: " + join_with(low, ","),
    "medium: " + join_with(medium, ","),
    "high: " + join_with(high, ","),
    "unknown: " + join_with(unknown, ","),
  ])
}

///|
pub fn third_party_release_ready(
  packages : Array[ThirdPartyPackage],
  policy : Policy,
) -> Bool {
  third_party_policy_passes(packages, policy) &&
  third_party_sources_missing(packages).is_empty() &&
  third_party_without_notice(packages).is_empty()
}

///|
pub fn third_party_release_report(
  packages : Array[ThirdPartyPackage],
  policy : Policy,
) -> String {
  let rows : Array[String] = [
    "third-party release ready: " +
    bool_word(third_party_release_ready(packages, policy)),
    "",
    third_party_report(packages, policy),
    "",
    "risk summary",
    third_party_risk_summary(packages),
  ]
  let missing = third_party_sources_missing(packages)
  if !missing.is_empty() {
    rows.push("")
    rows.push("packages without source URL: " + join_with(missing, ","))
  }
  join_lines(rows)
}
