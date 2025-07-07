/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public enum ApkIndexProvides: Hashable, Sendable {
  case any(name: String)
  case specific(name: String, version: String)
}

extension ApkIndexProvides {
  init(requirement: ApkVersionRequirement) throws(ProvidesError) {
    self = switch requirement.versionSpec {
    case .any(invert: false):
      .any(name: requirement.name)
    case .constraint(invert: false, op: .equals, let version):
      .specific(name: requirement.name, version: version)
    default:
      throw .badConstraint
    }
  }

  func satisfies(_ requirement: ApkVersionRequirement) -> Bool {
    switch self {
    case .any(let name):
      return requirement.name == name
    case .specific(let name, let version):
      return requirement.name == name &&
        requirement.versionSpec.satisfied(by: version)
    }
  }

  enum ProvidesError: Error, LocalizedError {
    case badConstraint

    var errorDescription: String? {
      switch self {
      case .badConstraint: "Invalid constraint type, must only be equals"
      }
    }
  }
}

extension ApkIndexProvides: CustomStringConvertible {
  public var description: String {
    switch self {
    case .any(let name): name
    case .specific(let name, let version): "\(name)=\(version)"
    }
  }

  public var name: String {
    switch self {
    case .any(let name): name
    case .specific(let name, _): name
    }
  }
}
