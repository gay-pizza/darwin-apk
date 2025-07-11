/*
 * darwin-apk © 2024, 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

struct DpkGraphCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(commandName: "graph")

  func run() async throws(ExitCode) {
    do {
      let localRepositories = try await ApkRepositoriesConfig()

      var timerStart = DispatchTime.now()
      let pkgIndex = try await ApkIndexReader.resolve(localRepositories.repositories, fetch: .lazy)
      print("Index build took \(timerStart.distance(to: .now()).seconds) seconds")
      try pkgIndex.description.write(to: URL(filePath: "packages.txt"), atomically: false, encoding: .utf8)

      timerStart = DispatchTime.now()
      let providerCache = ApkIndexProviderCache(index: pkgIndex)
      var graph = ApkPackageGraph()
      graph.buildGraphNode(index: pkgIndex, providers: providerCache)
      print("Graph build took \(timerStart.distance(to: .now()).seconds) seconds")

      try graph.shallowIsolates.map { pkgIndex.at(node: $0).nameDescription }.joined(separator: "\n")
        .write(to: URL(filePath: "shallowIsolates.txt"), atomically: false, encoding: .utf8)
      try graph.deepIsolates.map { pkgIndex.at(node: $0).nameDescription }.joined(separator: "\n")
        .write(to: URL(filePath: "deepIsolates.txt"), atomically: false, encoding: .utf8)

      timerStart = DispatchTime.now()
#if false
      let sorted = try graph.parallelOrderSort()
      print("Parallel sort took \(timerStart.distance(to: .now()).seconds) seconds")

      if var out = TextFileWriter(URL(filePath: "sorted.txt")) {
        for (i, set) in sorted.enumerated() {
          print("\(i):", to: &out)
          for item in set {
            let pkg = pkgIndex.at(node: item)
            print("  \(pkg.nameDescription)", to: &out)
          }
          print(to: &out)
        }
      }
#else
      let sorted = try graph.orderSort()
      print("Order sort took \(timerStart.distance(to: .now()).seconds) seconds")

      try sorted.map { node in pkgIndex.at(node: node).nameDescription }.joined(separator: "\n")
        .write(to: URL(filePath: "sorted.txt"), atomically: false, encoding: .utf8)
#endif
    } catch {
      fatalError(error.localizedDescription)
    }
  }
}

fileprivate extension DispatchTimeInterval {
  var seconds: Double {
    switch self {
    case .seconds(let value):      Double(value)
    case .milliseconds(let value): Double(value) / 1_000
    case .microseconds(let value): Double(value) / 1_000_000
    case .nanoseconds(let value):  Double(value) / 1_000_000_000
    case .never: .infinity
    @unknown default: fatalError("Unsupported")
    }
  }
}
