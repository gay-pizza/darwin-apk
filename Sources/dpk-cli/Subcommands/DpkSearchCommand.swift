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
      eprint("Only one of \(self._regex.description) and \(self._exact.description) is allowed")
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

    let localRepositories = try await ApkRepositoriesConfig()
    let index: ApkIndex
    do {
      index = try await ApkIndexReader.resolve(localRepositories, fetch: .local)
    } catch {
      eprint("Failed to build package index: \(error.localizedDescription)")
      throw .failure
    }

    var results = [ApkIndexPackage]()
    for package in index.packages {
      if match.match(package.name) || (!self.nameOnly && match.match(package.packageDescription)) {
        results.append(package)
      }
    }

    results.sort { lhs, rhs in
      switch lhs.name.localizedCaseInsensitiveCompare(rhs.name) {
      case .orderedSame:
        ApkVersionCompare.compare(lhs.version, rhs.version) == .greater
      case .orderedDescending: false
      case .orderedAscending: true
      }
    }

    for package in results {
      print(package.shortDescription)
    }
  }
}
