/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CryptoKit

public struct ApkIndexUpdater {
  var repositories: [String]
  var architectures: [String]

  public init() {
    self.repositories = [
      "https://dl-cdn.alpinelinux.org/alpine/v3.20/main",
      "https://dl-cdn.alpinelinux.org/alpine/v3.20/community"
    ]
    // other archs: "armhf", "armv7", "loongarch64", "ppc64le", "riscv64", "s390x", "x86"
    self.architectures = [ "aarch64" /*, "x86_64" */ ]
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

    let graph: ApkPackageGraph
    do {
      let tables = try repositories.map { try readIndex(URL(filePath: $0.localName)) }
      graph = ApkPackageGraph(index: ApkIndex.merge(tables))
      graph.buildGraphNode()

      try graph.pkgIndex.description.write(to: URL(filePath: "packages.txt"), atomically: false, encoding: .utf8)
    } catch {
      fatalError(error.localizedDescription)
    }

    if var out = TextFileWriter(URL(filePath: "shallowIsolates.txt")) {
      for node in graph.shallowIsolates { print(node, to: &out) }
    }
    if var out = TextFileWriter(URL(filePath: "deepIsolates.txt")) {
      for node in graph.deepIsolates { print(node, to: &out) }
    }
  }

  private func readIndex(_ indexURL: URL) throws -> ApkIndex {
    let tarSignature: [TarReader.Entry]
    let tarRecords: [TarReader.Entry]

    print("Archive:    \(indexURL.lastPathComponent)")

    let durFormat = Duration.UnitsFormatStyle(
      allowedUnits: [ .seconds, .milliseconds ],
      width: .condensedAbbreviated,
      fractionalPart: .show(length: 3))
    let gzipStart = ContinuousClock.now

    var tars = [Data]()
    do {
      var file: any InputStream = try FileInputStream(indexURL)
      //var file: any InputStream = try MemoryInputStream(buffer: try Data(contentsOf: indexURL))
      tars.append(try GZip.read(inStream: &file))
      tars.append(try GZip.read(inStream: &file))
      
    } catch {
      fatalError(error.localizedDescription)
    }

    print("Gzip time:  \((ContinuousClock.now - gzipStart).formatted(durFormat))")
    let untarStart = ContinuousClock.now

    var signatureStream = MemoryInputStream(buffer: tars[0])
    tarSignature = try TarReader.read(&signatureStream)
    var recordsStream = MemoryInputStream(buffer: tars[1])
    tarRecords = try TarReader.read(&recordsStream)

    guard case .file(let signatureName, _) = tarSignature.first
    else { fatalError("Missing signature") }
    guard let apkIndexFile = tarRecords.firstFile(name: "APKINDEX")
    else { fatalError("APKINDEX missing") }
    guard let description = tarRecords.firstFile(name: "DESCRIPTION")
    else { fatalError("DESCRIPTION missing") }

    print("TAR time:   \((ContinuousClock.now - untarStart).formatted(durFormat))")
    let indexStart = ContinuousClock.now
    defer {
      print("Index time: \((ContinuousClock.now - indexStart).formatted(durFormat))")
    }

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
