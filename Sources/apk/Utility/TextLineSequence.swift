/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import System

internal struct TextLineSequence<Base: InputStream>: Sequence where Base.Element == UInt8 {
  public typealias Element = String

  private var _stream: Base

  fileprivate init(_ stream: Base) {
    self._stream = stream
  }

  public struct Iterator: IteratorProtocol {
    public typealias Element = String

    fileprivate init(base stream: Base) {
      self._stream = stream
    }

    private var _stream: Base
    private var _bytes = [UInt8]()
    private var _lastChar: UInt8? = nil
    private var _eof = false

    @inline(__always) private mutating func readRawLine() {
      if let first = self._lastChar {
        // Add any holdovers from reading the previous line to the start of this one
        self._bytes.append(first)
        self._lastChar = nil
      }

      while true {
        guard let nextChar = self._stream.next() else {
          self._eof = true
          break
        }
        if nextChar == 0x0A {  // "\n"
          break
        } else if nextChar == 0x0D {  // "\r"
          // Match CRLF to avoid double newlines when dealing with DOS-based text
          let lookAhead = self._stream.next()
          if _slowPath(lookAhead != 0x0A) {
            // If it wasn't an LF then queue it for the next line
            self._lastChar = nextChar
          }
          break
        }
        self._bytes.append(nextChar)
      }
    }

    public mutating func next() -> String? {
      // Return early if we already hit the end of the stream
      guard !self._eof else {
        return nil
      }

      // Read raw bytes until newline
      self.readRawLine()
      defer {
        self._bytes.removeAll(keepingCapacity: true)
      }

      if _fastPath(!self._bytes.isEmpty) {
        // Convert and return line
        return String(decoding: self._bytes, as: UTF8.self)
      } else {
        if _fastPath(!self._eof) {
          // Don't bother decoding empty lines and just return an empty string
          return ""
        }
        // Ignore the final empty newline
        return nil
      }
    }
  }

  public func makeIterator() -> Iterator {
    Iterator(base: self._stream)
  }
}

internal extension InputStream {
  var lines: TextLineSequence<InputStream> {
    .init(self)
  }
}
