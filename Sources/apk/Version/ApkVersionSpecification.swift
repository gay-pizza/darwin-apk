/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

enum ApkVersionSpecification: Equatable, Hashable, Sendable {
  case any(invert: Bool = false)
  case constraint(invert: Bool = false, op: Operator, version: String)
}

extension ApkVersionSpecification {
  enum Operator: Equatable, Sendable {
    case equals
    case fuzzyEquals
    case greater
    case less
    case greaterEqual
    case lessEqual
    case greaterFuzzy
    case lessFuzzy
  }
}

internal extension ApkVersionSpecification {
  @inlinable var conflict: Bool {
    switch self {
    case .any(invert: true), .constraint(invert: true, _, _):
      return true
    default:
      return false
    }
  }
}

extension ApkVersionSpecification.Operator: CustomStringConvertible {
  var description: String {
    switch self {
    //case .checksum:     "><"
    case .lessEqual:    "<="
    case .greaterEqual: ">="
    case .lessFuzzy:    "<~"
    case .greaterFuzzy: ">~"
    case .equals:       "="
    case .less:         "<"
    case .greater:      ">"
    case .fuzzyEquals:  "~"
    }
  }
}
