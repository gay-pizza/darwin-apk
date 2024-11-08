// SPDX-License-Identifier: Apache-2.0

import Foundation

struct ApkIndexDownloader {
  func downloadFile(remote remoteURL: URL, destination destLocalURL: URL) {
    let sem = DispatchSemaphore.init(value: 0)
    let downloadTask = URLSession.shared.downloadTask(with: remoteURL) { url, response, error in
      if let localURL = url {
        do {
          // Replace existing APKINDEX.tar.gz files
          if FileManager.default.fileExists(atPath: destLocalURL.path()) {
            try FileManager.default.removeItem(at: destLocalURL)
          }
          // Move temporary to the new location
          try FileManager.default.moveItem(at: localURL, to: destLocalURL)
        } catch {
          print("Download error: \(error.localizedDescription)")
        }
      }
      sem.signal()
    }
    downloadTask.resume()
    sem.wait()
  }
}
