/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

public struct ApkRepositoriesConfig {
  public let repositories: [ApkIndexRepository]

  public init() async throws(ExitCode) {
    do {
      self.repositories = try await Self.readConfig(name: "repositories").flatMap { repo in
        Self.readConfig(name: "arch").map { arch in
          ApkIndexRepository(name: repo, arch: arch)
        }
      }.reduce(into: []) { $0.append($1) }
    } catch {
      eprint("Failed to read repository configurations, \(error.localizedDescription)")
      throw .failure
    }
  }

  private static func readConfig(name: String)
      -> AsyncFilterSequence<AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, String>> {
    return URL(filePath: name, directoryHint: .notDirectory).lines
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty && $0.first != "#" }  // Ignore empty & commented lines
  }
}

public extension ApkIndex {
  @inlinable static func resolve(_ config: ApkRepositoriesConfig, fetch: ApkIndexFetchMode) async throws -> Self {
    try await Self.resolve(config.repositories, fetch: fetch)
  }
}
