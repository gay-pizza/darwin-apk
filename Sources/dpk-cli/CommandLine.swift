// SPDX-License-Identifier: Apache-2.0

import ArgumentParser

@main
struct DarwinApkCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dpk",
    abstract: "Command-line interface for managing packages installed via darwin-apk.",
    subcommands: [
      Install.self,
      Remove.self,
      Update.self,
      Upgrade.self
    ])
}

extension DarwinApkCLI {
  struct Install: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "add",
      abstract: "Install package(s) to the system.",
      aliases: [ "install", "i", "a" ])

    @Argument(help: "One or more package names to install to the system.")
    var packages: [String]

    func run() throws {
      print("installing \"\(packages.joined(separator: "\", \""))\"")
    }
  }

  struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "remove",
      abstract: "Remove specified package(s) from the system.",
      aliases: [ "uninstall", "del", "rem", "r" ])

    @Argument(help: "One or more package names to uninstall from the system.")
    var packages: [String]

    func run() throws {
      print("uninstalling \"\(packages.joined(separator: "\", \""))\"")
    }
  }

  struct Update: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update",
      abstract: "Update the system package repositories.",
      aliases: [ "u" ])

    func run() throws {
      print("updating package repositories")
    }
  }

  struct Upgrade: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "upgrade",
      abstract: "Upgrade installed packages.",
      aliases: [ "U" ])

    @Argument(help: "Optionally specify packages to upgrade. Otherwise upgrade all packages installed on the system.")
    var packages: [String] = []

    func run() throws {
      if packages.isEmpty {
        print("upgrading system")
      } else {
        print("upgrading invidual packages: \"\(packages.joined(separator: "\", \""))\"")
      }
    }
  }
}
