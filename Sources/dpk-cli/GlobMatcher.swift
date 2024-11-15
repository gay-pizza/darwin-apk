/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser

struct GlobMatcher: PatternMatcher {
  private let _patterns: [String]
  private let _flags: Int32

  init(patterns: [String], ignoreCase: Bool) throws(ArgumentParser.ExitCode) {
    self._patterns = patterns
    self._flags = ignoreCase ? FNM_CASEFOLD : 0
  }

  func match(_ field: String) -> Bool {
    for pattern in self._patterns {
      // Quick hack to make matching without explicit globs easier
      if pattern.rangeOfCharacter(from: .init(charactersIn: "*?[]")) == nil {
        if self._flags & FNM_CASEFOLD != 0 {
          return field.localizedCaseInsensitiveContains(pattern)
        } else {
          return field.contains(pattern)
        }
      }
      let res = fnmatch(pattern, field, self._flags)
      if res == FNM_NOMATCH {
        continue
      } else if res == 0 {
        return true
      }
      fatalError("fnmatch error \(res)")
    }
    return false
  }
}
