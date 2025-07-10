/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class ApkPackageGraphNode {
  public let packageID: ApkIndex.Index
  public var parentIDs = [ApkIndex.Index]()
  public var children: [ChildRef]

  private weak var _graph: ApkPackageGraph?

  public var package: ApkIndexPackage {
    self._graph!.pkgIndex.packages[self.packageID]
  }
  public var parents: [ApkIndexPackage] {
    self.parentIDs.map { index in self._graph!.pkgIndex.packages[index] }
  }
  public var childPackages: [ApkIndexPackage] {
    self.children.map { child in self._graph!.pkgIndex.packages[child.packageID] }
  }

  @inlinable public var isShallow: Bool { self.parentIDs.isEmpty }
  @inlinable public var isDeep: Bool { self.children.isEmpty }

  internal init(_ graph: ApkPackageGraph, id: Int, children: [ChildRef]) {
    self._graph = graph
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

extension ApkPackageGraphNode: CustomStringConvertible {
  public var description: String {
    let package = self.package
    var result = "  \(package.nameDescription):\n"
    if !self.parentIDs.isEmpty {
      result += "    parents:\n"
      for parent in self.parents {
        result += "      \(parent.nameDescription)\n"
      }
    }
    if !self.children.isEmpty {
      result += "    children:\n"
      for child in self.children {
        let childPackage = self._graph!.pkgIndex.packages[child.packageID]
        result += "      "
        switch child.constraint {
        case .dependency: result += "dep="
        case .installIf: result += "installIf="
        }
        result += childPackage.nameDescription
        result += ", "
        result += child.versionSpec.description
        result += "\n"
      }
    }
    return result
  }
}
