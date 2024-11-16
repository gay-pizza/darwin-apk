/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndexUpdater {
  public var repositories: [ApkIndexRepository]

  public init() {
    self.repositories = []
  }

  public func update() {
    let downloader = ApkIndexDownloader()
    for repo in self.repositories {
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
      let tables = try self.repositories.map { try Self.readIndex(URL(filePath: $0.localName)) }
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

  public static func readIndex(_ indexURL: URL) throws -> ApkIndex {
    let tarSignature: [TarReader.Entry]
    let tarRecords: [TarReader.Entry]

    let arcName = indexURL.lastPathComponent

    let durFormat = Duration.UnitsFormatStyle(
      allowedUnits: [ .seconds, .milliseconds ],
      width: .condensedAbbreviated,
      fractionalPart: .show(length: 3))
    let gzipStart = ContinuousClock.now

    var tars = [Data]()
    do {
      var file = try FileInputStream(indexURL)
      //var file = try MemoryInputStream(buffer: try Data(contentsOf: indexURL))
      var gzip = GZipReader()
      tars.append(try gzip.read(inStream: file))
      tars.append(try gzip.read(inStream: file))
    } catch {
      fatalError(error.localizedDescription)
    }

    print("\(arcName): Gzip time:  \((ContinuousClock.now - gzipStart).formatted(durFormat))")
    let untarStart = ContinuousClock.now

    let signatureStream = MemoryInputStream(buffer: tars[0])
    tarSignature = try TarReader.read(signatureStream)
    let recordsStream = MemoryInputStream(buffer: tars[1])
    tarRecords = try TarReader.read(recordsStream)

    guard case .file(let signatureName, _) = tarSignature.first
    else { fatalError("Missing signature") }
    guard let apkIndexFile = tarRecords.firstFile(name: "APKINDEX")
    else { fatalError("APKINDEX missing") }
    guard let description = tarRecords.firstFile(name: "DESCRIPTION")
    else { fatalError("DESCRIPTION missing") }

    print("\(arcName): TAR time:   \((ContinuousClock.now - untarStart).formatted(durFormat))")
    let indexStart = ContinuousClock.now
    defer {
      print("\(arcName): Index time: \((ContinuousClock.now - indexStart).formatted(durFormat))")
    }

    return try ApkIndex(raw:
      try ApkRawIndex(lines: MemoryInputStream(buffer: apkIndexFile).lines))
  }
}
