/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import ArgumentParser

struct DpkRemoveCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove",
    abstract: "Remove specified package(s) from the system.",
    aliases: [ "r", "rem", "del", "uninstall" ])

  @Argument(help: "One or more package(s) to uninstall from the system.")
  var packages: [String]

  func run() throws {
    print("uninstalling \"\(packages.joined(separator: "\", \""))\"")
  }
}
