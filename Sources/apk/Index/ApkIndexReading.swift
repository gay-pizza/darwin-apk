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
