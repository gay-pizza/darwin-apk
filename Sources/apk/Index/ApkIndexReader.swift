/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndexReader {
  static func read(from indexURL: URL) throws -> ApkIndex {
    let timed = false
    var timer: ContinuousClock.Instant!
    let durFormat = Duration.UnitsFormatStyle(
      allowedUnits: [ .seconds, .milliseconds ],
      width: .condensedAbbreviated,
      fractionalPart: .show(length: 3))

    if timed {
      timer = ContinuousClock.now
    }

    let file = try FileInputStream(indexURL)
    //var file = try MemoryInputStream(buffer: try Data(contentsOf: indexURL))
    var gzip = GZipReader()
    var tarRecords = [TarReader.Entry]()
    for tarData in try (0..<2).map({ _ in try gzip.read(inStream: file) }) {
      let tarStream = MemoryInputStream(buffer: tarData)
      tarRecords += try TarReader.read(tarStream)
    }

    guard case .file(let signatureName, _) = tarRecords.first else {
      throw ReadingError.missingSignature
    }
    guard let apkIndexFile = tarRecords.firstFile(name: "APKINDEX") else {
      throw ReadingError.missingIndex
    }
    guard let description = tarRecords.firstFile(name: "DESCRIPTION") else {
      throw ReadingError.missingDescription
    }

    if timed {
      print("\(indexURL.lastPathComponent): Extract time:  \((ContinuousClock.now - timer).formatted(durFormat))")
      timer = ContinuousClock.now
    }

    let index = try ApkIndex(raw:
      try ApkRawIndex(lines: MemoryInputStream(buffer: apkIndexFile).lines))

    if timed {
      print("\(indexURL.lastPathComponent): Index time: \((ContinuousClock.now - timer).formatted(durFormat))")
    }

    return index
  }

  public static func resolve<S: Sequence<ApkIndexRepository>>(_ repositories: S, fetch: FetchMode) async throws -> ApkIndex {
    try await withThrowingTaskGroup(of: ApkIndex.self) { group in
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
          let index = try Self.read(from: local)
          return index
        }
      }
      return try await ApkIndex.merge(group.reduce(into: []) { $0.append($1) })
    }
  }
}

public extension ApkIndexReader {
  enum FetchMode: Sendable {
    case update
    case lazy
    case local
  }

  enum ReadingError: Error, LocalizedError {
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
}
