/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

class ApkPackageGraph {
  let pkgIndex: ApkIndex

  private var _nodes = [ApkPackageGraphNode]()

  var nodes: [ApkPackageGraphNode] { self._nodes }
  var shallowIsolates: [ApkPackageGraphNode] { self._nodes.filter(\.parents.isEmpty) }
  var deepIsolates: [ApkPackageGraphNode] { self._nodes.filter(\.children.isEmpty) }

  init(index: ApkIndex) {
    self.pkgIndex = index
  }

  func buildGraphNode() {
    var provides = [String: Int]()

    for (idx, package) in self.pkgIndex.packages.enumerated() {
      provides[package.name] = idx
      for provision in package.provides {
        provides[provision.name] = idx
      }
    }

    for package in pkgIndex.packages {
      self._nodes.append(.init(
        package: package,
        children: package.dependencies.compactMap { dependency in
          guard let id = provides[dependency.requirement.name] else {
            return nil
          }
          return .init(self, id: id, constraint: .dep(version: dependency.requirement.versionSpec))
        } + package.provides.compactMap { provision in
          guard let id = provides[provision.name] else {
            return nil
          }
          return .init(self, id: id, constraint: .provision)
        } + package.installIf.compactMap { installIf in
          guard let id = provides[installIf.requirement.name] else {
            return nil
          }
          return .init(self, id: id, constraint: .installIf(version: installIf.requirement.versionSpec ))
        }
      ))
    }

    var reverseDependencies = [ApkIndexRequirementRef: [ApkIndexRequirementRef]]()
    for (index, node) in self._nodes.enumerated() {
      for child in node.children {
        reverseDependencies[child, default: []].append(
          .init(self, id: index, constraint: child.constraint)
        )
      }
    }

    for (ref, parents) in reverseDependencies {
      self._nodes[ref.packageID].parents = parents
    }
  }
}
