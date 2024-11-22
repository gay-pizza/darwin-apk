/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser

struct GlobMatcher: PatternMatcher {
  private let _patterns: [Pattern]
  private let _flags: Int32

  init(patterns: [String], ignoreCase: Bool) throws(ArgumentParser.ExitCode) {
    // Quick hack to make matching without explicit globs easier
    let globChars = CharacterSet(charactersIn: "*?[]")
    self._patterns = patterns.map { pattern in
      if pattern.unicodeScalars.contains(where: globChars.contains) {
        .wildcard(glob: pattern)
      } else {
        .globless(match: pattern)
      }
    }
    self._flags = ignoreCase ? FNM_CASEFOLD : 0
  }

  func match(_ field: String) -> Bool {
    for pattern in self._patterns {
      switch pattern {
      case .globless(let match):
        if self._flags & FNM_CASEFOLD != 0 {
          return field.localizedCaseInsensitiveContains(match)
        } else {
          return field.contains(match)
        }
      case .wildcard(let glob):
        let res = fnmatch(glob, field, self._flags)
        if res == FNM_NOMATCH {
          continue
        } else if res == 0 {
          return true
        }
        fatalError("fnmatch error \(res)")
      }
    }
    return false
  }
}

private extension GlobMatcher {
  enum Pattern {
    case wildcard(glob: String)
    case globless(match: String)
  }
}
