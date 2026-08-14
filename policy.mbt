// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub struct Policy {
  allowed : Array[String]
  denied : Array[String]
  allow_copyleft : Bool
  require_osi : Bool
} derive(Debug, Eq)

///|
pub fn permissive_policy() -> Policy {
  {
    allowed: [
      "MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Zlib", "0BSD",
    ],
    denied: [],
    allow_copyleft: false,
    require_osi: true,
  }
}

///|
pub fn strict_policy(allowed : Array[String]) -> Policy {
  {
    allowed: normalize_license_list(allowed),
    denied: [],
    allow_copyleft: false,
    require_osi: true,
  }
}

///|
pub fn normalize_license_list(items : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for item in items {
    result.push(canonical_license(item))
  }
  unique_strings(result)
}

///|
pub fn policy_errors(text : String, policy : Policy) -> Array[String] {
  match parse(text).expr {
    Some(expr) => policy_errors_expr(expr, policy)
    None => ["parse error: " + parse(text).error]
  }
}

///|
pub fn policy_errors_expr(expr : Expr, policy : Policy) -> Array[String] {
  match expr {
    License(id) => policy_errors_license(id, policy)
    LicenseWithException(id, ex) => policy_errors_with_exception(id, ex, policy)
    And(left, right) =>
      unique_strings(
        policy_errors_expr(left, policy) + policy_errors_expr(right, policy),
      )
    Or(left, right) => {
      let left_errors = policy_errors_expr(left, policy)
      let right_errors = policy_errors_expr(right, policy)
      if left_errors.is_empty() || right_errors.is_empty() {
        []
      } else {
        unique_strings(
          prefix_errors("left option: ", left_errors) +
          prefix_errors("right option: ", right_errors),
        )
      }
    }
  }
}

///|
pub fn policy_errors_with_exception(
  id : String,
  ex : String,
  policy : Policy,
) -> Array[String] {
  let errors = policy_errors_license(id, policy)
  if !is_known_exception(ex) {
    errors.push("unknown exception: " + ex)
  }
  errors
}

///|
pub fn policy_errors_license(id : String, policy : Policy) -> Array[String] {
  let errors : Array[String] = []
  if !policy.allowed.is_empty() && !contains_string(policy.allowed, id) {
    errors.push("license not allowed: " + id)
  }
  if contains_string(policy.denied, id) {
    errors.push("license denied: " + id)
  }
  if policy.require_osi && !is_osi_license(id) {
    errors.push("license is not OSI-approved in catalog: " + id)
  }
  if !policy.allow_copyleft && is_copyleft_license(id) {
    errors.push("copyleft license not allowed: " + id)
  }
  errors
}

///|
pub fn prefix_errors(prefix : String, errors : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for item in errors {
    result.push(prefix + item)
  }
  result
}

///|
pub fn policy_report(text : String, policy : Policy) -> String {
  let errors = policy_errors(text, policy)
  if errors.is_empty() {
    "ok"
  } else {
    join_lines(errors)
  }
}

///|
pub fn policy_allows(text : String, policy : Policy) -> Bool {
  policy_errors(text, policy).is_empty()
}
