/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndexUpdater {
  public var repositories: [ApkIndexRepository]

  public init() {
    self.repositories = []
  }

  public func buildGraph() async {
    let graph: ApkPackageGraph
    do {
      graph = ApkPackageGraph(index: try await ApkIndexReader.resolve(self.repositories, fetch: .lazy))
      graph.buildGraphNode()

      try graph.pkgIndex.description.write(to: URL(filePath: "packages.txt"), atomically: false, encoding: .utf8)
    } catch {
      fatalError(error.localizedDescription)
    }

    if var out = TextFileWriter(URL(filePath: "shallowIsolates.txt")) {
      for node in graph.shallowIsolates { print(node, to: &out) }
    }
    if var out = TextFileWriter(URL(filePath: "deepIsolates.txt")) {
      for node in graph.deepIsolates { print(node, to: &out) }
    }
  }
}
