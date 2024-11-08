// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct MemoryInputStream: InputStream {
  private var _buf: [UInt8]! = nil
  private let _sli: ArraySlice<UInt8>
  private let _len: Int
  private var _idx = 0

  public init(buffer: Data) {
    self._len = buffer.count
    self._buf = [UInt8](repeating: 0, count: self._len)
    self._buf.withUnsafeMutableBytes { _ = buffer.copyBytes(to: $0) }
    self._sli = self._buf[...]
  }

  public init(view: ArraySlice<UInt8>) {
    self._sli = view
    self._len = view.count
  }

  public mutating func seek(_ whence: StreamWhence) throws(StreamError) {
    let (position, overflow) = switch whence {
    case .set(let position):   (position, false)
    case .current(let offset): self._idx.addingReportingOverflow(offset)
    case .end(let offset):     self._len.addingReportingOverflow(offset)
    }
    if overflow {
      throw .overflow
    } else if position < 0 {
      throw .seekRange
    } else {
      self._idx = position
    }
  }

  public var tell: Int {
    get throws(StreamError) {
      self._idx
    }
  }

  public mutating func read(_ count: Int) throws(StreamError) -> Data {
    let beg = min(self._idx, self._len)
    let end = min(self._idx + count, self._len)
    let bytes = Data(self._sli[beg..<end])
    self._idx += beg.distance(to: end)
    return bytes
  }

  public mutating func next() -> UInt8? {
    if self._idx < self._len {
      let byte = self._sli[self._idx]
      self._idx += 1
      return byte
    } else {
      return nil
    }
  }
}
