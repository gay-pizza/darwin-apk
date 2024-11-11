/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import System

public protocol Stream {
  mutating func seek(_ whence: StreamWhence) throws(StreamError)
  var tell: Int { get throws(StreamError) }
}

public enum StreamWhence {
  case set(_ position: Int)
  case current(_ offset: Int)
  case end(_ offset: Int)
}

public enum StreamError: Error, LocalizedError {
  case unsupported
  case seekRange
  case overflow
  case fileHandleError(_ error: any Error)
  case fileDescriptorError(_ error: Errno)

  public var errorDescription: String? {
    switch self {
    case .unsupported: "Unsupported operation"
    case .seekRange: "Seek out of range"
    case .overflow: "Stream position overflowed"
    case .fileHandleError(let error): "Error from file handle: \(error.localizedDescription)"
    case .fileDescriptorError(let error): "\(error)"
    }
  }
}
