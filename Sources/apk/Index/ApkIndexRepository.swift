/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CryptoKit

public struct ApkIndexRepository {
  public let name: String
  public let arch: String
  public let discriminator: String

  private static func resolveApkIndex(_ repo: String, _ arch: String)
    -> String { "\(repo)/\(arch)/APKINDEX.tar.gz" }

  public var url: URL {
    URL(string: Self.resolveApkIndex(self.name, self.arch))!
  }

  public var localName: String { "APKINDEX.\(discriminator).tar.gz" }

  public init(name repo: String, arch: String) {
    self.name = repo
    self.arch = arch

    let urlSHA1Digest = Data(Insecure.SHA1.hash(data: Data(Self.resolveApkIndex(repo, arch).utf8)))
    self.discriminator = urlSHA1Digest.subdata(in: 0..<3).map { String(format: "%02x", $0) }.joined()
  }
}
