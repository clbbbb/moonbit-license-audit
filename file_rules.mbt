///|
pub struct FileRule {
  path : String
  kind : String
  should_scan : Bool
  reason : String
} derive(Debug, Eq)

///|
pub fn file_rule(
  path : String,
  kind : String,
  should_scan : Bool,
  reason : String,
) -> FileRule {
  { path, kind, should_scan, reason }
}

///|
pub fn classify_path(path : String) -> FileRule {
  let lower = lower_ascii(path)
  if lower.find("_build/") is Some(_) || lower.find("\\_build\\") is Some(_) {
    file_rule(path, "build-artifact", false, "MoonBit build output")
  } else if lower.find("node_modules/") is Some(_) ||
    lower.find("\\node_modules\\") is Some(_) {
    file_rule(path, "dependency-cache", false, "external dependency cache")
  } else if lower.find("vendor/") is Some(_) ||
    lower.find("\\vendor\\") is Some(_) {
    file_rule(
      path, "vendored-source", true, "vendored source should keep license headers",
    )
  } else if lower.has_suffix(".mbt") {
    file_rule(path, "moonbit-source", true, "MoonBit source file")
  } else if lower.has_suffix(".md") {
    file_rule(path, "documentation", false, "documentation checked separately")
  } else if lower.has_suffix(".yml") || lower.has_suffix(".yaml") {
    file_rule(path, "configuration", false, "workflow/config file")
  } else if lower.has_suffix(".json") || lower.has_suffix(".toml") {
    file_rule(path, "metadata", false, "metadata file")
  } else {
    file_rule(path, "other", false, "not a source file")
  }
}

///|
pub fn paths_to_scan(paths : Array[String]) -> Array[String] {
  let rows : Array[String] = []
  for path in paths {
    let rule = classify_path(path)
    if rule.should_scan {
      rows.push(path)
    }
  }
  rows
}

///|
pub fn should_scan_path(path : String) -> Bool {
  classify_path(path).should_scan
}

///|
pub fn file_rules_report(paths : Array[String]) -> String {
  let rows : Array[String] = []
  for path in paths {
    let rule = classify_path(path)
    rows.push(
      rule.path +
      "," +
      rule.kind +
      "," +
      bool_word(rule.should_scan) +
      "," +
      rule.reason,
    )
  }
  join_lines(rows)
}

///|
pub fn filter_sources_by_rule(
  paths : Array[String],
  sources : Array[String],
) -> (Array[String], Array[String]) {
  let kept_paths : Array[String] = []
  let kept_sources : Array[String] = []
  let limit = min_int(paths.length(), sources.length())
  for index = 0; index < limit; index = index + 1 {
    if should_scan_path(paths[index]) {
      kept_paths.push(paths[index])
      kept_sources.push(sources[index])
    }
  }
  (kept_paths, kept_sources)
}

///|
pub fn ignored_paths_report(paths : Array[String]) -> String {
  let rows : Array[String] = []
  for path in paths {
    let rule = classify_path(path)
    if !rule.should_scan {
      rows.push(path + ": " + rule.reason)
    }
  }
  if rows.is_empty() {
    "no ignored paths"
  } else {
    join_lines(rows)
  }
}
