/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

struct ApkIndexDependency: ApkIndexRequirementRef {
  let name: String
  let versionSpec: ApkVersionSpecification

  init(name: String, version spec: ApkVersionSpecification) {
    self.name = name
    self.versionSpec = spec
  }
}

extension ApkIndexDependency: CustomStringConvertible {
  var description: String {
    switch self.versionSpec {
    case .any: self.name
    case .conflict: "!\(self.name)"
    case .constraint(let op, let version): "\(self.name)\(op)\(version)"
    }
  }
}
