/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

enum ApkVersionSpecification: Equatable, Hashable {
  case any(invert: Bool)
  case constraint(invert: Bool, op: Operator, version: String)
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
