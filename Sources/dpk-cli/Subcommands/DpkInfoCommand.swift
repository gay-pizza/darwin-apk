/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import ArgumentParser
import darwin_apk

struct DpkInfoCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "info",
    abstract: "Show information about a package",
    aliases: [ "S", "show" ])

  @Argument(help: "One or more package names to print information about.")
  var packages: [String]

  func run() async throws(ExitCode) {
    let localRepositories = try await ApkRepositoriesConfig()
    let index: ApkIndex
    do {
      index = try await ApkIndexReader.resolve(localRepositories, fetch: .local)
    } catch {
      eprint("Failed to build package index: \(error.localizedDescription)")
      throw .failure
    }

    self.packages.lazy
      .flatMap(index.filter)
      .map(\.description)
      .forEach { print($0) }
  }
}
