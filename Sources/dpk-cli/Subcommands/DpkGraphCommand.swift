/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

struct DpkGraphCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(commandName: "graph")

  func run() async throws(ExitCode) {
    let graph: ApkPackageGraph
    do {
      let localRepositories = try await ApkRepositoriesConfig()

      var timerStart = DispatchTime.now()
      var pkgIndex = try await ApkIndexReader.resolve(localRepositories.repositories, fetch: .lazy)
      print("Index build took \(timerStart.distance(to: .now()).seconds) seconds")
      try pkgIndex.description.write(to: URL(filePath: "packages.txt"), atomically: false, encoding: .utf8)

      timerStart = DispatchTime.now()
      try graph = ApkPackageGraph(from: &pkgIndex)
      print("Graph build took \(timerStart.distance(to: .now()).seconds) seconds")

      try graph.shallowIsolates.map { pkgIndex.packages[$0].nameDescription }.joined(separator: "\n")
        .write(to: URL(filePath: "shallowIsolates.txt"), atomically: false, encoding: .utf8)
      try graph.deepIsolates.map { pkgIndex.packages[$0].nameDescription }.joined(separator: "\n")
        .write(to: URL(filePath: "deepIsolates.txt"), atomically: false, encoding: .utf8)

      let sorted = try graph.sorted(breakCycles: false)
      try sorted.map { pkgIndex.packages[$0].nameDescription }.joined(separator: "\n")
        .write(to: URL(filePath: "sorted.txt"), atomically: false, encoding: .utf8)

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
    @unknown default:
    fatalError("Unsupported")
    }
  }
}
