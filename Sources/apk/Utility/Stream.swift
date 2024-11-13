/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import System

public class Stream {
  func seek(_ whence: Whence) throws(StreamError) {
    throw .unsupported
  }

  var tell: Int {
    get throws(StreamError) {
      throw .unsupported
    }
  }
}

extension Stream {
  public enum Whence {
    case set(_ position: Int)
    case current(_ offset: Int)
    case end(_ offset: Int)
  }
}

public enum StreamError: Error, LocalizedError {
  case unsupported
  case notImplemented
  case seekRange
  case overflow
  case fileHandleError(_ error: any Error)
  case fileDescriptorError(_ error: Errno)

  public var errorDescription: String? {
    switch self {
    case .unsupported: "Unsupported operation"
    case .notImplemented: "The stream object doesn't implement this function"
    case .seekRange: "Seek out of range"
    case .overflow: "Stream position overflowed"
    case .fileHandleError(let error): "Error from file handle: \(error.localizedDescription)"
    case .fileDescriptorError(let error): "\(error)"
    }
  }
}
