/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

struct DpkSearchCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "search",
    abstract: "Search for packages with a pattern matching name and description",
    aliases: [ "s" ])

  @Flag
  var nameOnly: Bool = false

  @Argument
  var patterns: [String]

  func run() async throws(ExitCode) {
    let re: [Regex<_StringProcessing.AnyRegexOutput>]
    do {
      re = try patterns.map(Regex.init)
    } catch {
      print("Bad pattern \(error.localizedDescription)")
      throw .validationFailure
    }

    let repositories: [String], architectures: [String]
    do {
      repositories = try await PropertyFile.read(name: "repositories")
    } catch {
      print("Failed to read repositories: \(error.localizedDescription)")
      throw .failure
    }
    do {
      architectures = try await PropertyFile.read(name: "arch")
    } catch {
      print("Failed to read arch: \(error.localizedDescription)")
      throw .failure
    }

    let localRepositories = repositories.flatMap { repo in
      architectures.map { arch in
        URL(filePath: ApkIndexRepository(name: repo, arch: arch).localName, directoryHint: .notDirectory)
      }
    }
    let index: ApkIndex
    do {
      index = ApkIndex.merge(try localRepositories.map(ApkIndex.init))
    } catch {
      print("Failed to build package index: \(error.localizedDescription)")
      throw .failure
    }

    do {
      for package in index.packages {
        for pattern in re {
          if try
              pattern.firstMatch(in: package.name) != nil ||
              (!self.nameOnly && pattern.firstMatch(in: package.packageDescription) != nil) {
            print(package.shortDescription)
            break
          }
        }
      }
    } catch {
      print("Something went wrong: \(error.localizedDescription)")
      throw .failure
    }
  }
}

struct PropertyFile {
  static func read(name: String) async throws -> [String] {
    try await URL(filePath: name, directoryHint: .notDirectory).lines
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty && $0.first != "#" }  // Ignore empty & commented lines
      .reduce(into: [String]()) { $0.append($1) }
  }
}
