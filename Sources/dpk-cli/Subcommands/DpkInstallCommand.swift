/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import ArgumentParser

struct DpkInstallCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add",
    abstract: "Install package(s) to the system.",
    aliases: [ "a", "install" ])

  @Argument(help: "One or more package names to install to the system.")
  var packages: [String]

  func run() throws {
    print("installing \"\(packages.joined(separator: "\", \""))\"")
  }
}
