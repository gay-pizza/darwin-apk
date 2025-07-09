/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

/*
struct ApkIndexRequirementRef {
  private weak var _graph: ApkPackageGraph?

  let packageID: Int
  let constraint: Constraint

  init(_ graph: ApkPackageGraph, id: Int, constraint: Constraint) {
    self._graph = graph
    self.packageID = id
    self.constraint = constraint
  }

  var package: ApkIndexPackage {
    self._graph!.pkgIndex.packages[self.packageID]
  }

  func satisfied(by other: ApkVersionRequirement) -> Bool {
    true
  }
  
  func normalize() -> ApkIndexRequirementRef {
    .init(self._graph!, id: self.packageID, constraint: .dep(version: .any()))
  }
}

extension ApkIndexRequirementRef: Equatable, Hashable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.packageID == rhs.packageID && lhs.constraint == rhs.constraint
  }

  func hash(into hasher: inout Hasher) {
    self.packageID.hash(into: &hasher)
    self.constraint.hash(into: &hasher)
  }
}

extension ApkIndexRequirementRef {
  enum Constraint: Hashable {
    case dep(version: ApkVersionSpecification)
    case provision
    case installIf(version: ApkVersionSpecification)
  }
}

extension ApkIndexRequirementRef: CustomStringConvertible {
  var description: String {
    guard let package = self._graph?.pkgIndex.packages[self.packageID] else {
      return String()
    }
    return switch self.constraint {
    case .dep(let version):
      "dep=\(ApkVersionRequirement(name: package.name, spec: version))"
    case .provision:
      "provides=\(package.name)"
    case .installIf(let version):
      "installIf=\(ApkVersionRequirement(name: package.name, spec: version))"
    }
  }
}
*/
