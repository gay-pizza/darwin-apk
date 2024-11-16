/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

struct DpkUpdateCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update",
    abstract: "Update the system package repositories.",
    aliases: [ "u" ])

  @Flag(help: "Index on-disk cache")
  var lazyDownload: Bool = false

  func run() async throws {
    let repositories = try await ApkRepositoriesConfig().repositories
    print("Updating package repositories")
    let index = try await ApkIndex.resolve(repositories, fetch: self.lazyDownload ? .lazy : .update)
    print("Indexed \(index.packages.count) package(s)")
  }
}
