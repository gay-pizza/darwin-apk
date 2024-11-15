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
    do {
      self.repositories = try await Self.readConfig(name: "repositories").flatMap { repo in
        Self.readConfig(name: "arch").map { arch in
          ApkIndexRepository(name: repo, arch: arch)
        }
      }.reduce(into: []) { $0.append($1) }
    } catch {
      print("Failed to read repository configurations, \(error.localizedDescription)")
      throw .failure
    }
  }

  var localRepositories: [URL] {
    self.repositories.map { repo in
      URL(filePath: repo.localName, directoryHint: .notDirectory)
    }
  }

  private static func readConfig(name: String)
      -> AsyncFilterSequence<AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, String>> {
    return URL(filePath: name, directoryHint: .notDirectory).lines
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty && $0.first != "#" }  // Ignore empty & commented lines
  }
}
