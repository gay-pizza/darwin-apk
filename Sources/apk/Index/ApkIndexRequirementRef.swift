/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

protocol ApkIndexRequirementRef: Equatable, Hashable {
  var name: String { get }
  var invert: Bool { get }

  init(name: String, version spec: ApkVersionSpecification)

  func satisfied(by other: ApkIndexPackage) -> Bool
}

extension ApkIndexRequirementRef {
  var invert: Bool { false }
  func satisfied(by _: ApkIndexPackage) -> Bool { true }

  static func extract<T: ApkIndexRequirementRef>(_ blob: String) throws(ApkRequirement.ParseError) -> [T] {
    return try blob.components(separatedBy: " ")
      .map { token throws(ApkRequirement.ParseError) in
        let (name, versionSpec) = try ApkRequirement.extract(blob: token)
        return .init(name: name, version: versionSpec)
      }
  }
}
