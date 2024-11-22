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
    eprint("Updating package repositories")
    let index = try await ApkIndexReader.resolve(repositories, fetch: self.lazyDownload ? .lazy : .update)
    eprint("Indexed \(index.packages.count) package(s)")
  }
}
