/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import ArgumentParser

@main
struct DarwinApkCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dpk",
    abstract: "Command-line interface for managing packages installed via darwin-apk.",
    subcommands: [
      DpkInstallCommand.self,
      DpkRemoveCommand.self,
      DpkUpdateCommand.self,
      DpkUpgradeCommand.self,
      DpkSearchCommand.self,
      DpkInfoCommand.self
    ])
}
