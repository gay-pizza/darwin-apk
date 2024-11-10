/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

struct DpkUpdateCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update",
    abstract: "Update the system package repositories.",
    aliases: [ "u" ])

  func run() throws {
    print("Updating package repositories")
    var updater = ApkIndexUpdater()
    updater.update()
  }
}
