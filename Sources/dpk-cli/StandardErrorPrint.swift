/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

internal func eprint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
  var stderr = FileHandle.standardError
  print(items, separator: separator, terminator: terminator, to: &stderr)
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    self.write(Data(string.utf8))
  }
}
