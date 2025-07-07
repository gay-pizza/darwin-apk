/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndex: Sendable {
  public let packages: [ApkIndexPackage]
  public typealias Index = Array<ApkIndexPackage>.Index
}

public extension ApkIndex {
  func first(name: String) -> ApkIndexPackage? {
    self.packages.first {
      $0.name == name
    }
  }

  func filter(name: String) -> [ApkIndexPackage] {
    self.packages.filter {
      $0.name == name
    }
  }

  func resolve(requirement: ApkVersionRequirement) -> ApkIndexPackage? {
    self.packages.first { pkg in
      return (pkg.name == requirement.name && requirement.versionSpec.satisfied(by: pkg.version))
        || pkg.provides.contains(where: { $0.satisfies(requirement) })
    }
  }

  func resolveIndex(requirement: ApkVersionRequirement) -> Index? {
    self.packages.firstIndex { pkg in
      return (pkg.name == requirement.name && requirement.versionSpec.satisfied(by: pkg.version))
        || pkg.provides.contains(where: { $0.satisfies(requirement) })
    }
  }
}

public extension ApkIndex {
  static func merge<S: Sequence>(_ tables: S) -> Self where S.Element == Self {
    Self.init(packages: tables.flatMap(\.packages))
  }

  static func merge(_ tables: Self...) -> Self {
    Self.init(packages: tables.flatMap(\.packages))
  }
}

extension ApkIndex {
  init(raw: ApkRawIndex) throws(ApkIndexError) {
    self.packages = try raw.packages.map { records throws(ApkIndexError) in
      do {
        return try ApkIndexPackage(raw: records)
      } catch {
        throw .parseError(records.lookup("P") ?? "UNKNOWN", error)
      }
    }
  }
}

extension ApkIndex: CustomStringConvertible {
  public var description: String {
    self.packages.map(String.init).joined(separator: "\n")
  }
}

public enum ApkIndexError: Error {
  case parseError(String, any Error)
}

extension ApkIndexError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .parseError(let packageName, let cause):
      return "Failed to parse index for \"\(packageName)\": \(cause.localizedDescription)"
    }
  }
}
