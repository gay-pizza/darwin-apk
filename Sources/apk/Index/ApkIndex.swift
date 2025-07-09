/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndex: Sendable {
  public let packages: [ApkIndexPackage]
  public typealias Index = Array<ApkIndexPackage>.Index

  lazy var providers: [(ApkIndexProvides, Index)] = {
    self.packages.enumerated().flatMap { index, pkg in
      [ (.specific(name: pkg.name, version: pkg.version), index) ] + pkg.provides.map { ($0, index) }
    }
  }()
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

  mutating func resolve(requirement: ApkVersionRequirement) -> ApkIndexPackage? {
    self.providers.filter { prv in prv.0.satisfies(requirement) }
      .map { self.packages[$1] }.max()
  }

  mutating func resolveIndex(requirement: ApkVersionRequirement) -> Index? {
    self.providers.filter { prv in prv.0.satisfies(requirement) }
      .max { self.packages[$0.1] < self.packages[$1.1] }?.1
  }
}

extension ApkIndexPackage: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    // Prefer highest declared provider priority
    lhs.providerPriority ?? 0 < rhs.providerPriority ?? 0
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
