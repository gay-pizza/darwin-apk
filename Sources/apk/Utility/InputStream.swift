/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public protocol InputStream: Stream, IteratorProtocol where Element == UInt8 {
  mutating func read(_ count: Int) throws(StreamError) -> Data
  mutating func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) throws(StreamError) -> Int
}

public extension InputStream {
  mutating func read(_ size: Int, items: Int) throws(StreamError) -> Data {
    try self.read(size * items)
  }
}

public extension InputStream {
  mutating func next() -> UInt8? {
    try? self.read(1).first
  }
}
