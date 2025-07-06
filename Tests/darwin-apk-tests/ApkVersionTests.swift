/*
 * darwin-apk © 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Testing
@testable import darwin_apk

@Test func testParseDependency() {
  let tests: [String: ApkVersionRequirement] = [
    "bash":
      .init(name: "bash", spec: .any()),
    "!libdbus":
      .init(name: "libdbus", spec: .any(invert: true)),
    "libapparmor=4.1.0-r2":
      .init(name: "libapparmor", spec: .constraint(op: .equals, version: "4.1.0-r2")),
    "python3~3.12":
      .init(name: "python3", spec: .constraint(op: .fuzzyEquals, version: "3.12")),
    "so:libc.musl-x86_64.so.1":
      .init(name: "so:libc.musl-x86_64.so.1", spec: .any()),
    "!alsa-lib<1.2.14-r0":
      .init(name: "alsa-lib", spec: .constraint(invert: true, op: .less, version: "1.2.14-r0")),
    "!alsa-lib>1.2.14-r0":
      .init(name: "alsa-lib", spec: .constraint(invert: true, op: .greater, version: "1.2.14-r0")),
    "!lld20-libs<20.1.2-r0":
      .init(name: "lld20-libs", spec: .constraint(invert: true, op: .less, version: "20.1.2-r0")),
    "!lld20-libs>20.1.2-r0":
      .init(name: "lld20-libs", spec: .constraint(invert: true, op: .greater, version: "20.1.2-r0")),
    "!lld20<20.1.2-r0":
      .init(name: "lld20", spec: .constraint(invert: true, op: .less, version: "20.1.2-r0")),
    "!lld20>20.1.2-r0":
      .init(name: "lld20", spec: .constraint(invert: true, op: .greater, version: "20.1.2-r0")),
  ]
  for valid in tests {
    #expect((try? ApkVersionRequirement(extract: valid.key[...])) == valid.value,
      "Expect: \(valid.key) == \(valid.value)")
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

@Test func testVersionComparion() {
  func test(_ spec: ApkVersionSpecification, _ version: String) -> Bool { spec.satisfied(by: version) }
  #expect(test(.any(), "15.6-r0"))
  #expect(test(.constraint(op: .equals,       version: "15.6"),   "15.6"))
  #expect(test(.constraint(op: .fuzzyEquals,  version: "15.6"),   "15.6b"))
  #expect(test(.constraint(op: .greaterEqual, version: "15.6"),   "15.6"))
  #expect(test(.constraint(op: .lessEqual,    version: "15.6"),   "15.6"))
  #expect(!test(.constraint(op: .greater,     version: "15.6"),   "15.6"))
  #expect(!test(.constraint(op: .less,        version: "15.6"),   "15.6"))
  #expect(test(.constraint(op: .less,         version: "15.6"),   "14.7.6"))
  #expect(test(.constraint(op: .greaterEqual, version: "13.7.6"), "15.6"))
}
