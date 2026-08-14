// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 clbbbb

///|
pub fn known_licenses() -> Array[String] {
  [
    "0BSD", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "BSL-1.0", "CC0-1.0", "CDDL-1.0",
    "EPL-2.0", "GPL-2.0-only", "GPL-2.0-or-later", "GPL-3.0-only", "GPL-3.0-or-later",
    "ISC", "LGPL-2.1-only", "LGPL-2.1-or-later", "LGPL-3.0-only", "LGPL-3.0-or-later",
    "MIT", "MPL-2.0", "Unlicense", "Zlib",
  ]
}

///|
pub fn known_exceptions() -> Array[String] {
  [
    "Autoconf-exception-3.0", "Bison-exception-2.2", "Classpath-exception-2.0", "GCC-exception-3.1",
    "LLVM-exception", "OpenSSL-exception",
  ]
}

///|
pub fn canonical_license(id : String) -> String {
  let value = trim_ascii(id)
  for known in known_licenses() {
    if lower_ascii(known) == lower_ascii(value) {
      return known
    }
  }
  value
}

///|
pub fn canonical_exception(id : String) -> String {
  let value = trim_ascii(id)
  for known in known_exceptions() {
    if lower_ascii(known) == lower_ascii(value) {
      return known
    }
  }
  value
}

///|
pub fn is_known_license(id : String) -> Bool {
  contains_string(known_licenses(), canonical_license(id))
}

///|
pub fn is_known_exception(id : String) -> Bool {
  contains_string(known_exceptions(), canonical_exception(id))
}

///|
pub fn osi_approved() -> Array[String] {
  [
    "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "BSL-1.0", "CDDL-1.0", "EPL-2.0",
    "GPL-2.0-only", "GPL-2.0-or-later", "GPL-3.0-only", "GPL-3.0-or-later", "ISC",
    "LGPL-2.1-only", "LGPL-2.1-or-later", "LGPL-3.0-only", "LGPL-3.0-or-later", "MIT",
    "MPL-2.0", "Zlib",
  ]
}

///|
pub fn is_osi_license(id : String) -> Bool {
  contains_string(osi_approved(), canonical_license(id))
}

///|
pub fn deprecated_licenses() -> Array[String] {
  [
    "Apache-1.0", "Apache-1.1", "GPL-1.0", "GPL-2.0", "GPL-3.0", "LGPL-2.0", "LGPL-2.1",
  ]
}

///|
pub fn deprecated_exceptions() -> Array[String] {
  []
}

///|
pub fn is_deprecated_license(id : String) -> Bool {
  contains_string(deprecated_licenses(), canonical_license(id))
}

///|
pub fn is_deprecated_exception(id : String) -> Bool {
  contains_string(deprecated_exceptions(), canonical_exception(id))
}

///|
pub fn copyleft_licenses() -> Array[String] {
  [
    "GPL-2.0-only", "GPL-2.0-or-later", "GPL-3.0-only", "GPL-3.0-or-later", "LGPL-2.1-only",
    "LGPL-2.1-or-later", "LGPL-3.0-only", "LGPL-3.0-or-later", "EPL-2.0", "MPL-2.0",
  ]
}

///|
pub fn is_copyleft_license(id : String) -> Bool {
  contains_string(copyleft_licenses(), canonical_license(id))
}
