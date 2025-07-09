/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftGraph

public class ApkPackageGraph {
  let graph: UnweightedGraph<ApkIndex.Index>

  public var shallowIsolates: [ApkIndex.Index] {
    self.graph.indices.lazy.filter { index in !self.graph.edges.contains { edge in edge.endIndex == index } }
      .map { index in self.graph.vertexAtIndex(index) }
  }
  public var deepIsolates: [ApkIndex.Index] {
    self.graph.indices.lazy.filter { index in self.graph.edgesForIndex(index).isEmpty }
      .map { index in self.graph.vertexAtIndex(index) }
  }

  public init(from pkgIndex: inout ApkIndex) throws(GraphError) {
    self.graph = UnweightedGraph<ApkIndex.Index>()

    // Add each package to the graph
    for pkgIdx in pkgIndex.packages.indices {
      // Skip packages already added by requirements
      guard !self.graph.vertexInGraph(vertex: pkgIdx) else {
        continue
      }
      // Add package ID as a vertex
      let u = self.graph.addVertex(pkgIdx)

      // Add dependent packages to the graphs and link them via edges
      let pkg = pkgIndex.packages[pkgIdx]
      for dep in pkg.dependencies {
        // Resolve package dependency
        guard let depIdx = pkgIndex.resolveIndex(requirement: dep.requirement) else {
          // It's okay to skip missing conflicts
          if dep.requirement.versionSpec.isConflict {
            continue
          }
          // Didn't find a satisfactory dependency in the index
          //throw .missingDependency(dep.requirement, pkg)
          print("WARN: Couldn't satisfy \"\(dep.requirement)\" required by \"\(pkg.nameDescription)\"")
          continue
        }

        // Get the graph vertex of dependency, or add it to the graph if it doesn't exist
        let v = self.graph.indexOfVertex(depIdx) ?? self.graph.addVertex(depIdx)

        self.graph.addEdge(fromIndex: u, toIndex: v, directed: true)
      }
    }
  }
}

extension ApkPackageGraph {
  public func sorted(breakCycles: Bool = true) throws(SortError) -> [ApkIndex.Index] {
    if !breakCycles {
      guard let sorted = self.graph.topologicalSort() else {
        throw .cyclicDependency(cycles: self.graph.detectCycles().description)
      }
      return sorted.reversed()
    }
    fatalError("Not yet implemented")

    /*
    var results = [[ApkIndex.Index]]()

    // Map all nodes to all of their children, remove any self dependencies
    var working = self.graph.isDAG
    var working = self._nodes.reduce(into: [ApkPackageGraphNode: Set<ApkPackageGraphNode>]()) { d, node in
      d[node] = Set(node.children.filter { child in
        if case .dep(let version) = child.constraint {
          !version.conflict && child.packageID != node.packageID
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
      var set = Set(working
        .filter { _, children in children.isEmpty }
        .map(\.key))

      // If nothing was satisfied in this loop, check for cycles
      // If no cycles exist and the working set is empty, resolve is complete
      if set.isEmpty {
        if working.isEmpty {
          break
        }

        let cycles = self.graph.detectCycles()

        // Error if cycle breaking is turned off
        if !breakCycles {
          throw .cyclicDependency(cycles: cycles.map { node, dependency in
              "\(node) -> \(dependency)"
            }.joined(separator: "\n"))
        }

        // Break cycles by setting the new resolution set to dependencies that cycled
        set = Set(cycles.flatMap { [$0.0, $0.1] })
      }

      // Add installation set to list of installation sets
      results.append(Array(set))

      // Filter the working set for anything that wasn't dealt with this iteration
      working = working.filter { node, _ in
        !set.contains(node)
      }.reduce(into: [ApkPackageGraphNode: Set<ApkPackageGraphNode>]()) { d, node in
        d[node.key] = node.value.subtracting(set)
      }
    }
    */
  }
}

extension ApkPackageGraph {
  public enum GraphError: Error, LocalizedError {
    case missingDependency(ApkVersionRequirement, ApkIndexPackage)

    public var errorDescription: String? {
      switch self {
      case .missingDependency(let r, let p): "Couldn't satisfy \"\(r)\" required by \"\(p.nameDescription)\""
      }
    }
  }

  public enum SortError: Error, LocalizedError {
    case cyclicDependency(cycles: String)

    public var errorDescription: String? {
      switch self {
      case .cyclicDependency(let cycles): "Dependency cycles found:\n\(cycles)"
      }
    }
  }
}
