// SPDX-License-Identifier: Apache-2.0

import Foundation
import SWCompression
import CryptoKit

public struct ApkIndexUpdater {
  var repositories: [String]
  var architectures: [String]

  public init() {
    self.repositories = [
      "https://dl-cdn.alpinelinux.org/alpine/v3.21/main",
      "https://dl-cdn.alpinelinux.org/alpine/edge/community"
    ]
    // other archs: "armhf", "armv7", "loongarch64", "ppc64le", "riscv64", "s390x", "x86"
    self.architectures = [ "aarch64", "x86_64" ]
  }

  public func update() {
    let repositories = self.repositories.flatMap { repo in
      self.architectures.map { arch in
        Repository(name: repo, arch: arch)
      }
    }

    let downloader = ApkIndexDownloader()
    for repo in repositories {
      let localIndex = URL(filePath: repo.localName)
#if false
      let shouldDownload = true
#else
      let shouldDownload = !FileManager.default.fileExists(atPath: localIndex.path())
#endif
      if shouldDownload {
        print("Fetching index for \"\(repo.name)\"")
        downloader.downloadFile(remote: repo.url, destination: localIndex)
      }
    }

    let index: ApkIndex
    do {
      let tables = try repositories.map { try readIndex(URL(filePath: $0.localName)) }
      index = ApkIndex.merge(tables)
    } catch {
      fatalError(error.localizedDescription)
    }

    for package in index.packages {
      print("\(package.name):", package.dependencies)
    }
  }

  private func readIndex(_ indexURL: URL) throws -> ApkIndex {
    let tarSignature: [TarReader.Entry]
    let tarRecords: [TarReader.Entry]

    let tars = try GzipArchive.multiUnarchive(  // Slow...
      archive: Data(contentsOf: indexURL))
    assert(tars.count >= 2)

    var signatureStream = MemoryInputStream(buffer: tars[0].data)
    tarSignature = try TarReader.read(&signatureStream)
    var recordsStream = MemoryInputStream(buffer: tars[1].data)
    tarRecords = try TarReader.read(&recordsStream)

    guard case .file(let signatureName, _) = tarSignature.first
    else { fatalError("Missing signature") }
    print(signatureName)
    guard let apkIndexFile = tarRecords.firstFile(name: "APKINDEX")
    else { fatalError("APKINDEX missing") }
    guard let description = tarRecords.firstFile(name: "DESCRIPTION")
    else { fatalError("DESCRIPTION missing") }

    let reader = TextInputStream(binaryStream: MemoryInputStream(buffer: apkIndexFile))
    return try ApkIndex(raw:
      try ApkRawIndex(lines: reader.lines))
  }
}

extension ApkIndexUpdater {
  struct Repository {
    let name: String
    let arch: String
    let discriminator: String

    private static func resolveApkIndex(_ repo: String, _ arch: String)
      -> String { "\(repo)/\(arch)/APKINDEX.tar.gz" }
    var url: URL { URL(string: Self.resolveApkIndex(self.name, self.arch))! }
    var localName: String { "APKINDEX.\(discriminator).tar.gz" }

    init(name repo: String, arch: String) {
      self.name = repo
      self.arch = arch

      let urlSHA1Digest = Data(Insecure.SHA1.hash(data: Data(Self.resolveApkIndex(repo, arch).utf8)))
      self.discriminator = urlSHA1Digest.subdata(in: 0..<3).map { String(format: "%02x", $0) }.joined()
    }
  }
}
