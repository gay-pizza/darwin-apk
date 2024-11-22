/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndexDownloader {
  public static func fetch(repository: ApkIndexRepository) async throws(FetchError) -> URL {
    let localDestinationURL = URL(filePath: repository.localName)

    let tempLocationURL: URL, response: URLResponse
    do {
      (tempLocationURL, response) = try await URLSession.shared.download(from: repository.url)
    } catch {
      throw .downloadFailed(error)
    }
    guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
      throw .invalidServerResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
    }

    // Move index repository to destination location
    do {
      // Replace existing APKINDEX.tar.gz files
      if FileManager.default.fileExists(atPath: localDestinationURL.path()) {
        try FileManager.default.removeItem(at: localDestinationURL)
      }

      // Move downloaded file to the new location
      try FileManager.default.moveItem(at: tempLocationURL, to: localDestinationURL)
      return localDestinationURL
    } catch let error {
      throw .moveFailed(error)
    }
  }
}

public extension ApkIndexDownloader {
  enum FetchError: Error, LocalizedError {
    case invalidServerResponse(_ code: Int)
    case downloadFailed(_ err: any Error)
    case moveFailed(_ err: any Error)

    public var errorDescription: String? {
      switch self {
      case .invalidServerResponse(let code): "Server responded with HTTP response code \(code)"
      case .downloadFailed(let err):         "Failed to create session, \(err.localizedDescription)"
      case .moveFailed(let err):             "Couldn't move index, \(err.localizedDescription)"
      }
    }
  }
}
