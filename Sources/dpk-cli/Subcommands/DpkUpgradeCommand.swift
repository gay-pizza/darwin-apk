/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import ArgumentParser

struct DpkUpgradeCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "upgrade",
    abstract: "Upgrade installed packages.",
    aliases: [ "U" ])

  @Argument(help: "Optionally specify packages to upgrade. Otherwise upgrade all packages installed on the system.")
  var packages: [String] = []

  func run() throws {
    if packages.isEmpty {
      eprint("upgrading system")
    } else {
      eprint("upgrading individual packages: \"\(packages.joined(separator: "\", \""))\"")
    }
  }
}
