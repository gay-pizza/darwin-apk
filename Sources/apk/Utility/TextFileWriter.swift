/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

struct TextFileWriter: TextOutputStream {
  private var _hnd: FileHandle

  init?(_ to: URL) {
    let file = open(to.path(), O_WRONLY | O_CREAT | O_TRUNC | O_SYNC, 0o644)
    guard file >= 0 else {
      return nil
    }
    self._hnd = FileHandle(fileDescriptor: file, closeOnDealloc: true)
  }

  mutating func write(_ string: String) {
    if let data = string.data(using: .utf8) {
      try? self._hnd.write(contentsOf: data)
    }
  }

  mutating func close() throws {
    try self._hnd.close()
  }
}
