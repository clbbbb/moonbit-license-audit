///|
pub struct ReadmeAudit {
  has_title : Bool
  has_license : Bool
  has_install : Bool
  has_usage : Bool
  has_example : Bool
  mentioned_licenses : Array[String]
} derive(Debug, Eq)

///|
pub fn audit_readme(readme : String) -> ReadmeAudit {
  {
    has_title: readme_has_title(readme),
    has_license: readme_has_license_section(readme),
    has_install: readme_has_section(readme, "install") ||
    readme_has_section(readme, "installation"),
    has_usage: readme_has_section(readme, "usage") ||
    readme_has_section(readme, "example"),
    has_example: readme_has_code_block(readme),
    mentioned_licenses: mentioned_license_ids(readme),
  }
}

///|
pub fn readme_has_title(readme : String) -> Bool {
  for line in split_char(readme, '\n') {
    if trim_ascii(line).has_prefix("# ") {
      return true
    }
  }
  false
}

///|
pub fn readme_has_section(readme : String, title : String) -> Bool {
  let target = lower_ascii(title)
  for line in split_char(readme, '\n') {
    let clean = lower_ascii(trim_ascii(line))
    if clean.has_prefix("#") && clean.find(target) is Some(_) {
      return true
    }
  }
  false
}

///|
pub fn readme_has_license_section(readme : String) -> Bool {
  readme_has_section(readme, "license") ||
  lower_ascii(readme).find("license:") is Some(_)
}

///|
pub fn readme_has_code_block(readme : String) -> Bool {
  readme.find("```") is Some(_)
}

///|
pub fn mentioned_license_ids(readme : String) -> Array[String] {
  let lower = lower_ascii(readme)
  let rows : Array[String] = []
  for id in known_licenses() {
    match lower.find(lower_ascii(id)) {
      Some(_) => rows.push(id)
      None => ()
    }
  }
  unique_strings(rows)
}

///|
pub fn readme_audit_warnings(audit : ReadmeAudit) -> Array[String] {
  let rows : Array[String] = []
  if !audit.has_title {
    rows.push("README title is missing")
  }
  if !audit.has_license {
    rows.push("README license section is missing")
  }
  if !audit.has_install {
    rows.push("README install section is missing")
  }
  if !audit.has_usage {
    rows.push("README usage or example section is missing")
  }
  if !audit.has_example {
    rows.push("README runnable code block is missing")
  }
  rows
}

///|
pub fn readme_audit_report(readme : String) -> String {
  let audit = audit_readme(readme)
  let rows : Array[String] = [
    "title: " + bool_word(audit.has_title),
    "license section: " + bool_word(audit.has_license),
    "install section: " + bool_word(audit.has_install),
    "usage section: " + bool_word(audit.has_usage),
    "code example: " + bool_word(audit.has_example),
    "mentioned licenses: " + join_with(audit.mentioned_licenses, ","),
  ]
  push_section(rows, "README warnings", readme_audit_warnings(audit))
  join_lines(rows)
}

///|
pub fn readme_matches_package_license(
  readme : String,
  package_license : String,
) -> Bool {
  if package_license == "" || !is_valid(package_license) {
    false
  } else {
    let ids = mentioned_license_ids(readme)
    for id in licenses(parse_or_panic(package_license)) {
      if contains_string(ids, id) {
        return true
      }
    }
    false
  }
}
