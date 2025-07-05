/*
 * darwin-apk © 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Testing
import Foundation
@testable import darwin_apk

@Test func testDataHexExtensions() {
  let dat = Data([
    252, 197, 0, 65, 100, 194, 41, 76, 236, 129,
    67, 184, 142, 139, 24, 46, 124, 214, 197, 60])

  #expect(Data(hexEncoded: "BAD") == nil, "Uneven length")
  #expect(Data(hexEncoded: "fcc5004164c2294cec8143b88e8b182e7cd6c53c") == dat)
  #expect(Data(hexEncoded: "FCC5004164C2294CEC8143B88E8B182E7CD6C53C") == dat)
  #expect(dat.asHexString == "FCC5004164C2294CEC8143B88E8B182E7CD6C53C")
}

@Test func testIndexDigestDecode() {
  let randomData = { len in
    Data((0..<len).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })
  }
  #expect(ApkIndexDigest(type: .md5, data: randomData(16)) != nil, "MD5 manual constructor")
  #expect(ApkIndexDigest(type: .sha1, data: randomData(20)) != nil, "SHA-1 manual constructor")
  #expect(ApkIndexDigest(type: .sha256, data: randomData(32)) != nil, "SHA-2 256 manual constructor")

  #expect(ApkIndexDigest(decode: "X16aafecbf0ab3b0b4946a15197c0976c6bdcb1c89")
    == .init(type: .sha1, data: Data([
      106, 175, 236, 191, 10, 179, 176, 180, 148, 106,
      21, 25, 124, 9, 118, 198, 189, 203, 28, 137])),
      "Hex (legacy) SHA-1 checksum decoding")
  #expect(ApkIndexDigest(decode: "Q1agYuAjvQz131ugrr0WQtZBmSbcM=")
    == .init(type: .sha1, data: Data([
      106, 6, 46, 2, 59, 208, 207, 93, 245, 186,
      10, 235, 209, 100, 45, 100, 25, 146, 109, 195])),
      "Base64 SHA-1 checksum decoding")
  #expect(ApkIndexDigest(decode: "Q2RgDygGjQ6TBE38nLvdy9txh/PuRqm9bfmPppU6fCBqQ=")
    == .init(type: .sha256, data: Data([
      70, 0, 242, 128, 104, 208, 233, 48, 68, 223, 201, 203, 189, 220, 189, 183,
      24, 127, 62, 228, 106, 155, 214, 223, 152, 250, 105, 83, 167, 194, 6, 164])),
      "Base64 SHA-256 checksum decoding")

  #expect(ApkIndexDigest(decode: "Q1fAC5FUAUZuBpW1uE01XS4pCKcYg=")?.description
    == "[SHA-1] 7C00B915401466E0695B5B84D355D2E2908A7188", "Decode to description")
}
