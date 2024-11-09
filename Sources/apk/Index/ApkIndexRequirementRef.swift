// SPDX-License-Identifier: Apache-2.0

protocol ApkIndexRequirementRef: Equatable, Hashable {
  var name: String { get }
  var invert: Bool { get }

  init(extract: String) throws(ApkRequirement.ParseError)

  func satisfied(by other: ApkIndexPackage) -> Bool
}

extension ApkIndexRequirementRef {
  var invert: Bool { false }
  func satisfied(by _: ApkIndexPackage) -> Bool { true }

  static func == (lhs: Self, rhs: Self) -> Bool {
    return !(lhs.name != rhs.name && !lhs.invert)
  }

  func hash(into hasher: inout Hasher) {
    self.name.hash(into: &hasher)
  }

  static func extract<T: ApkIndexRequirementRef>(_ blob: String) throws(ApkRequirement.ParseError) -> [T] {
    return try blob.components(separatedBy: " ")
      .map { token throws(ApkRequirement.ParseError) in
        try .init(extract: token)
      }
  }
}
