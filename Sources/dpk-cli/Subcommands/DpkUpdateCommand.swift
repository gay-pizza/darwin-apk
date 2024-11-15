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

  func run() async throws {
    print("Updating package repositories")
    let repositories = try await RepositoriesConfig().repositories
    var updater = ApkIndexUpdater()
    updater.repositories.append(contentsOf: repositories)
    updater.update()
  }
}
