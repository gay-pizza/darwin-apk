/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class InputStream: Stream, IteratorProtocol {
  public typealias Element = UInt8

  public func read(_ count: Int) throws(StreamError) -> Data {
    throw .notImplemented
  }

  public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) throws(StreamError) -> Int {
    throw .notImplemented
  }

  public func next() -> UInt8? {
    try? self.read(1).first
  }
}

public extension InputStream {
  func read(_ size: Int, items: Int) throws(StreamError) -> Data {
    try self.read(size * items)
  }
}
