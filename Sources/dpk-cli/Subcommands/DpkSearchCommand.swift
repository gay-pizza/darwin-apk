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

  @Flag(name: .shortAndLong, help: "Use regular expressions instead of globbing")
  var regex: Bool = false
  @Flag(name: [ .customShort("x"), .long ], help: "Match given strings exactly")
  var exact: Bool = false
  @Flag(name: [ .customShort("I"), .long ], help: "Use case-sensitive matching")
  var caseSensitive: Bool = false
  @Flag(name: .shortAndLong, help: "Only match names instead of names & descriptions")
  var nameOnly: Bool = false

  @Argument
  var patterns: [String]

  func run() async throws(ExitCode) {
    if self.regex && self.exact {
      print("Only one of \(self._regex.description) and \(self._exact.description) is allowed")
      throw .validationFailure
    }

    let matcher: PatternMatcher.Type = if self.regex {
      RegexMatcher.self
    } else if self.exact {
      ExactMatcher.self
    } else {
      GlobMatcher.self
    }
    let match: any PatternMatcher
    match = try matcher.init(patterns: patterns, ignoreCase: !self.caseSensitive)

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

    for package in index.packages {
      if match.match(package.name) || (!self.nameOnly && match.match(package.packageDescription)) {
        print(package.shortDescription)
      }
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
