/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

enum ApkVersionSpecification: Equatable {
  case any
  case constraint(op: Operator, version: String)
  case conflict
}

extension ApkVersionSpecification: CustomStringConvertible {
  var description: String {
    switch self {
    case .any: ""
    case .conflict: "!"
    case .constraint(let op, let version): "\(op)\(version)"
    }
  }
}

extension ApkVersionSpecification {
  enum Operator: Equatable {
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
