///|
pub fn parse_policy_config(text : String) -> Policy {
  let mut allowed : Array[String] = []
  let mut denied : Array[String] = []
  let mut allow_copyleft = false
  let mut require_osi = true
  for line in split_char(text, '\n') {
    let clean = strip_config_comment(line)
    match config_pair(clean) {
      Some((key, value)) =>
        if key == "allow" || key == "allowed" {
          allowed = normalize_license_list(split_config_list(value))
        } else if key == "deny" || key == "denied" {
          denied = normalize_license_list(split_config_list(value))
        } else if key == "allow_copyleft" {
          allow_copyleft = parse_bool(value)
        } else if key == "require_osi" {
          require_osi = parse_bool(value)
        }
      None => ()
    }
  }
  { allowed, denied, allow_copyleft, require_osi }
}

///|
pub fn strip_config_comment(line : String) -> String {
  match line.find("#") {
    Some(index) => trim_ascii(line.unsafe_substring(start=0, end=index))
    None => trim_ascii(line)
  }
}

///|
pub fn config_pair(line : String) -> (String, String)? {
  match line.find("=") {
    Some(index) => {
      let key = lower_ascii(
        trim_ascii(line.unsafe_substring(start=0, end=index)),
      )
      let value = trim_ascii(
        line.unsafe_substring(start=index + 1, end=line.length()),
      )
      if key == "" {
        None
      } else {
        Some((key, value))
      }
    }
    None => None
  }
}

///|
pub fn split_config_list(text : String) -> Array[String] {
  let rows : Array[String] = []
  for item in split_char(text, ',') {
    let clean = trim_ascii(item)
    if clean != "" {
      rows.push(clean)
    }
  }
  rows
}

///|
pub fn parse_bool(text : String) -> Bool {
  let value = lower_ascii(trim_ascii(text))
  value == "true" || value == "yes" || value == "1" || value == "on"
}

///|
pub fn policy_config_report(policy : Policy) -> String {
  join_lines([
    "allowed=" + join_with(policy.allowed, ","),
    "denied=" + join_with(policy.denied, ","),
    "allow_copyleft=" + bool_word(policy.allow_copyleft),
    "require_osi=" + bool_word(policy.require_osi),
  ])
}

///|
pub fn merge_policy(base : Policy, extra : Policy) -> Policy {
  {
    allowed: if extra.allowed.is_empty() {
      base.allowed
    } else {
      extra.allowed
    },
    denied: unique_strings(base.denied + extra.denied),
    allow_copyleft: base.allow_copyleft || extra.allow_copyleft,
    require_osi: base.require_osi && extra.require_osi,
  }
}

///|
pub fn policy_from_mode(mode : String) -> Policy {
  let value = lower_ascii(trim_ascii(mode))
  if value == "permissive" {
    permissive_policy()
  } else if value == "copyleft-ok" {
    { allowed: [], denied: [], allow_copyleft: true, require_osi: true }
  } else if value == "any-known" {
    { allowed: [], denied: [], allow_copyleft: true, require_osi: false }
  } else {
    permissive_policy()
  }
}
