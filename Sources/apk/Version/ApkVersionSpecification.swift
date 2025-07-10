/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
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
  @inlinable var isConflict: Bool {
    switch self {
    case .any(invert: true), .constraint(invert: true, _, _):
      return true
    default:
      return false
    }
  }

  func satisfied(by version: String) -> Bool {
    switch self {
    case .any:
      //return true
      return ApkVersionCompare.validate(version)
    case .constraint(_ , let op, let requiredVersion):
      switch ApkVersionCompare.compare(version, requiredVersion, mode: op.isFuzzy ? .fuzzy : .normal) {
      case .equal:   return op.isEqual
      case .greater: return op.isGreater
      case .less:    return op.isLess
      default: return false
      }
    }
  }
}

internal extension ApkVersionSpecification.Operator {
  @inlinable var isFuzzy: Bool {
    switch self {
    case .fuzzyEquals, .lessFuzzy, .greaterFuzzy: return true
    default: return false
    }
  }

  @inlinable var isEqual: Bool {
    switch self {
    case .equals, .fuzzyEquals, .greaterEqual, .lessEqual, .greaterFuzzy, .lessFuzzy: true
    default: false
    }
  }

  @inlinable var isGreater: Bool {
    switch self {
    case .greater, .greaterEqual, .greaterFuzzy: true
    default: false
    }
  }

  @inlinable var isLess: Bool {
    switch self {
    case .less, .lessEqual, .lessFuzzy: true
    default: false
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

extension ApkVersionSpecification: CustomStringConvertible {
  var description: String {
    switch self {
      case .any(invert: false): "depend=any"
      case .any(invert: true): "conflict=any"
      case .constraint(invert: false, let op, let version): "depend\(op)\(version)"
      case .constraint(invert: true, let op, let version): "conflict\(op)\(version)"
    }
  }
}
