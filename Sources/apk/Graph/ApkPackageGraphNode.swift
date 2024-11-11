/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

class ApkPackageGraphNode {
  private weak var graph: ApkPackageGraph!
  let package: ApkIndexPackage

  //private var _parents = NSHashTable<ApkPackageGraphNode>.weakObjects()
  //private var _children = NSHashTable<ApkPackageGraphNode>.weakObjects()
  var parents = [ApkIndexRequirementRef]()
  var children: [ApkIndexRequirementRef]

  internal init(package: ApkIndexPackage, children: [ApkIndexRequirementRef]) {
    self.package = package
    self.children = children
  }
}

extension ApkPackageGraphNode: CustomStringConvertible {
  var description: String {
    var result = "node[\(self.package.name)]"
    if !self.parents.isEmpty {
      result += ", parents[\(self.parents.lazy.map(\.description).joined(separator: ", "))]"
    }
    if !self.children.isEmpty {
      result += ", children[\(self.children.lazy.map(\.description).joined(separator: ", "))]"
      
    }
    return result
  }
}
