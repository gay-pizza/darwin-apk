/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class ApkPackageGraph {
  public let pkgIndex: ApkIndex

  private var _nodes = [ApkPackageGraphNode]()

  public var nodes: [ApkPackageGraphNode] { self._nodes }
  public var shallowIsolates: [ApkPackageGraphNode] { self._nodes.filter(\.parents.isEmpty) }
  public var deepIsolates: [ApkPackageGraphNode] { self._nodes.filter(\.children.isEmpty) }

  public init(index: ApkIndex) {
    self.pkgIndex = index
  }

  public func buildGraphNode() {
    var provides = [String: Int]()

    for (idx, package) in self.pkgIndex.packages.enumerated() {
      provides[package.name] = idx
      for provision in package.provides {
        if !provides.keys.contains(provision.name) {
          provides[provision.name] = idx
        }
      }
    }

    for (id, package) in pkgIndex.packages.enumerated() {
      let children: [ApkIndexRequirementRef] = package.dependencies.filter { dependency in dependency.requirement.versionSpec != .conflict }.compactMap { dependency in
        guard let id = provides[dependency.requirement.name] else {
          return nil
        }
        return .init(self, id: id, constraint: .dep(version: dependency.requirement.versionSpec))
      }
      self._nodes.append(.init(self,
        id: id,
        children: children
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
      let package = self._nodes[ref.packageID].package
      self._nodes[ref.packageID].parents = parents
    }
  }
}

extension ApkPackageGraph {
  func findDependencyCycle(node: ApkPackageGraphNode) -> (ApkPackageGraphNode, ApkPackageGraphNode)? {
    var resolving = Set<Int>()
    var visited = Set<Int>()
    return self.findDependencyCycle(node: node, &resolving, &visited)
  }

  func findDependencyCycle(
    node: ApkPackageGraphNode,
    _ resolving: inout Set<Int>,
    _ visited: inout Set<Int>
  ) -> (ApkPackageGraphNode, ApkPackageGraphNode)? {
    for dependency in node.children {
      let depNode = self._nodes[dependency.packageID]
      if resolving.contains(depNode.packageID) {
        print("VIA \(resolving.map({ self._nodes[$0].package.name } )) CYCLE \(node.package.name) \(depNode.package.name)")
        return (node, depNode)
      }

      if !visited.contains(depNode.packageID) {
        resolving.insert(depNode.packageID)
        if let cycle = findDependencyCycle(node: depNode, &resolving, &visited) {
          return cycle
        }

        resolving.remove(depNode.packageID)
        visited.insert(depNode.packageID)
      }
    }

    return nil
  }

  public func parallelOrderSort(breakCycles: Bool = true) throws(SortError) -> [[ApkPackageGraphNode]] {
    var results = [[ApkPackageGraphNode]]()

    // Map all nodes to all of their children, remove any self dependencies
    var working = self._nodes.reduce(into: [ApkPackageGraphNode: Set<ApkPackageGraphNode>]()) { d, node in
      d[node] = Set(node.children.filter { child in
        if case .dep(let version) = child.constraint {
          version != .conflict && child.packageID != node.packageID
        } else { false }
      }.map { self._nodes[$0.packageID] })
    }

    // Collect all child nodes that aren't already in the map
    // This should be empty every time
    let extras = working.values.reduce(Set<ApkPackageGraphNode>()) { a, b in
      a.union(b)
    }.subtracting(working.keys)
    assert(extras.isEmpty, "Dangling nodes in the graph")

    // Put all extra nodes into the working map, with an empty set
    extras.forEach {
      working[$0] = .init()
    }

    while !working.isEmpty {
      // Set of all nodes now with satisfied dependencies
      var set = working
        .filter { _, children in children.isEmpty }
        .map(\.key)
      
      print("set \(set.count) working \(working.count)")
      // If nothing was satisfied in this loop, check for cycles
      // If no cycles exist and the working set is empty, resolve is complete
      if set.isEmpty {
        if working.isEmpty {
          break
        }

        let cycles = working.keys.compactMap { node in
          self.findDependencyCycle(node: node)
        }
        
        // Error if cycle breaking is turned off
        if !breakCycles {
          throw .cyclicDependency(cycles: cycles.map { node, dependency in
              "\(node) -> \(dependency)"
            }.joined(separator: "\n"))
        }
        
        // Break cycles by setting the new resolution set to dependencies that cycled
        set = cycles.flatMap { [$0.0, $0.1] }
        set = Array(Set(set))
      }
      
      print(set.map({ $0.package.name + " " + String($0.packageID) }))
      
      // Add installation set to list of installation sets
      results.append(set)

      // Filter the working set for anything that wasn't dealt with this iteration
      working = working.filter { node, _ in
        !set.contains(node)
      }.reduce(into: [ApkPackageGraphNode: Set<ApkPackageGraphNode>]()) { d, node in
        d[node.key] = node.value.subtracting(set)
      }
      
      for (what, deps) in working {
        print("\(what.packageID) \(what.package.name): \(deps.map { $0.package.name + " " + String($0.packageID) })")
      }
    }

    return results
  }

  public enum SortError: Error, LocalizedError {
    case cyclicDependency(cycles: String)

    var errorDescription: String {
      switch self {
      case .cyclicDependency(let cycles): "Dependency cycles found:\n\(cycles)"
      }
    }
  }
}
