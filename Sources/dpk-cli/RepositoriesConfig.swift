/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser
import darwin_apk

struct RepositoriesConfig {
  let repositories: [ApkIndexRepository]

  init() async throws(ExitCode) {
    let repositories: [String], architectures: [String]
    do {
      repositories = try await Self.read(name: "repositories")
    } catch {
      print("Failed to read repositories: \(error.localizedDescription)")
      throw .failure
    }
    do {
      architectures = try await Self.read(name: "arch")
    } catch {
      print("Failed to read arch: \(error.localizedDescription)")
      throw .failure
    }

    self.repositories = repositories.flatMap { repo in
      architectures.map { arch in
        ApkIndexRepository(name: repo, arch: arch)
      }
    }
  }

  var localRepositories: [URL] {
    self.repositories.map { repo in
      URL(filePath: repo.localName, directoryHint: .notDirectory)
    }
  }

  private static func read(name: String) async throws -> [String] {
    try await URL(filePath: name, directoryHint: .notDirectory).lines
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty && $0.first != "#" }  // Ignore empty & commented lines
      .reduce(into: [String]()) { $0.append($1) }
  }
}
