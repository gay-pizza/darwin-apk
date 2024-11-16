/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public extension ApkIndex {
  init(readFrom indexURL: URL) throws {
    let file = try FileInputStream(indexURL)
    var gzip = GZipReader()
    var tarRecords = [TarReader.Entry]()
    for tarData in try (0..<2).map({ _ in try gzip.read(inStream: file) }) {
      let tarStream = MemoryInputStream(buffer: tarData)
      tarRecords += try TarReader.read(tarStream)
    }

    guard case .file(let signatureName, _) = tarRecords.first else {
      throw ApkIndexReadingError.missingSignature
    }
    guard let apkIndexFile = tarRecords.firstFile(name: "APKINDEX") else {
      throw ApkIndexReadingError.missingIndex
    }
    guard let description = tarRecords.firstFile(name: "DESCRIPTION") else {
      throw ApkIndexReadingError.missingDescription
    }

    try self.init(raw:
      try ApkRawIndex(lines: MemoryInputStream(buffer: apkIndexFile).lines))
  }
}

public extension ApkIndex {
  static func resolve<S: Sequence>(_ repositories: S, fetch: ApkIndexFetchMode) async throws -> Self where S.Element == ApkIndexRepository {
    try await withThrowingTaskGroup(of: Self.self) { group in
      for repository in repositories {
        group.addTask(priority: .userInitiated) {
          let local: URL
          switch fetch {
          case .local:
            local = URL(filePath: repository.localName)
          case .lazy:
            if !FileManager.default.fileExists(atPath: repository.localName) {
              fallthrough
            }
            local = URL(filePath: repository.localName)
          case .update:
            //FIXME: Don't call print in the lib
            print("Fetching \"\(repository.resolved)\"")
            local = try await ApkIndexDownloader.fetch(repository: repository)
          }
          let index = try ApkIndex(readFrom: local)
          return index
        }
      }
      return try await ApkIndex.merge(group.reduce(into: []) { $0.append($1) })
    }
  }
}

public enum ApkIndexFetchMode: Sendable {
  case update
  case lazy
  case local
}

public enum ApkIndexReadingError: Error, LocalizedError {
  case missingSignature
  case missingIndex
  case missingDescription

  public var errorDescription: String? {
    switch self {
    case .missingSignature:   "Missing signature"
    case .missingIndex:       "APKINDEX missing"
    case .missingDescription: "DESCRIPTION missing"
    }
  }
}
