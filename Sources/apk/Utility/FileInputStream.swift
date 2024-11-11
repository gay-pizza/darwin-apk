/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import Darwin
import System

public struct FileInputStream: InputStream {
  private var _hnd: FileHandle

  public init(_ fileURL: URL) throws {
    self._hnd = try FileHandle(forReadingFrom: fileURL)
  }

  public mutating func seek(_ whence: StreamWhence) throws(StreamError) {
    let applyOffset = { (position: UInt64, offset: Int) throws(StreamError) -> UInt64 in
      if offset < 0 {
        let (newPosition, overflow) = position.subtractingReportingOverflow(UInt64(-offset))
        if overflow { throw .seekRange }
        return newPosition
      } else {
        let (newPosition, overflow) = position.addingReportingOverflow(UInt64(offset))
        if overflow { throw .overflow }
        return newPosition
      }
    }

    switch whence {
    case .set(let position):
      if position < 0 { throw .seekRange }
      do { try self._hnd.seek(toOffset: UInt64(truncatingIfNeeded: position)) }
      catch {
        throw .fileHandleError(error)
      }
    case .current(let offset):
      do { try self._hnd.seek(toOffset: try applyOffset(try self._hnd.offset(), offset)) }
      catch {
        if error is StreamError {
          throw error as! StreamError
        } else {
          throw .fileHandleError(error)
        }
      }
    case .end(let offset):
      do { try self._hnd.seek(toOffset: applyOffset(try self._hnd.seekToEnd(), offset)) }
      catch {
        if error is StreamError {
          throw error as! StreamError
        } else {
          throw .fileHandleError(error)
        }
      }
    }
  }

  public var tell: Int {
    get throws(StreamError) {
      let offset: UInt64
      do { offset = try self._hnd.offset() }
      catch {
        throw .fileHandleError(error)
      }
      if offset > Int.max { throw .overflow }
      return Int(truncatingIfNeeded: offset)
    }
  }

  public mutating func read(_ count: Int) throws(StreamError) -> Data {
    do {
      return try self._hnd.read(upToCount: count) ?? Data()
    } catch {
      throw .fileHandleError(error)
    }
  }

  public mutating func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) throws(StreamError) -> Int {
    let res = unistd.read(self._hnd.fileDescriptor, buffer, len)
    if res < 0 {
      throw .fileHandleError(Errno(rawValue: errno))
    }
    return res
  }
}
