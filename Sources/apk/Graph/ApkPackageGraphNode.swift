/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class ApkPackageGraphNode {
  public let packageID: ApkIndex.Index
  public var parentIDs = [ApkIndex.Index]()
  public var children: [ChildRef]

  @inlinable public var isShallow: Bool { self.parentIDs.isEmpty }
  @inlinable public var isDeep: Bool { self.children.isEmpty }

  internal init(_ graph: ApkPackageGraph, id: Int, children: [ChildRef]) {
    self.packageID = id
    self.children = children
  }
}

extension ApkPackageGraphNode: Equatable, Hashable {
  public static func == (lhs: ApkPackageGraphNode, rhs: ApkPackageGraphNode) -> Bool {
    lhs.packageID == rhs.packageID
  }

  public func hash(into hasher: inout Hasher) {
    self.packageID.hash(into: &hasher)
  }
}

extension ApkPackageGraphNode {
  public struct ChildRef {
    let constraint: Constraint
    let packageID: Int
    let versionSpec: ApkVersionSpecification
  }

  public enum Constraint {
    case dependency, installIf
  }
}

extension ApkIndex {
  public func at(node: ApkPackageGraphNode) -> ApkIndexPackage {
    self.packages[node.packageID]
  }
}
