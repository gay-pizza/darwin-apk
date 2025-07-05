/*
 * darwin-apk © 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Testing
@testable import darwin_apk

@Test func testParseDependency() {
  for valid in [
    "bash",
    "libapparmor=4.1.0-r2",
    "python3~3.12",
    "so:libc.musl-x86_64.so.1",
    "!alsa-lib<1.2.14-r0",
    "!alsa-lib>1.2.14-r0",
    "!lld20-libs<20.1.2-r0",
    "!lld20-libs>20.1.2-r0",
    "!lld20<20.1.2-r0",
    "!lld20>20.1.2-r0",
  ] {
    #expect(throws: Never.self, "Expected valid: \(valid)") {
      try ApkVersionRequirement(extract: valid[...])
    }
  }
}

@Test func testVersionValidation() {
  for valid in [
    "100",
    "1.0",
    "0-r1",
    "10.2.3-r100",
    "0.0.0_git20210122-r0",
    "0.20240527.191746-r2",
    "9100h-r4",
  ] {
    #expect(ApkVersionCompare.validate(valid), "Should be valid: \(valid)")
  }
  for invalid in [
    "a",
    "0r-10",
    "10.2.3-100",
  ] {
    #expect(!ApkVersionCompare.validate(invalid), "Should be invalid: \(invalid)")
  }
}
