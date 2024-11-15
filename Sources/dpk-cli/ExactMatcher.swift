/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser

struct ExactMatcher: PatternMatcher {
  private let _matches: [String]
  private let _ignoreCase: Bool

  init(patterns: [String], ignoreCase: Bool) throws(ArgumentParser.ExitCode) {
    self._matches = patterns
    self._ignoreCase = ignoreCase
  }

  func match(_ field: String) -> Bool {
    if self._ignoreCase {
      for match in self._matches {
        // May want to use localizedCaseInsensitiveCompare
        //  if localised descriptions ever become involved
        if field.caseInsensitiveCompare(match) == .orderedSame {
          return true
        }
      }
    } else {
      for match in self._matches {
        if field == match {
          return true
        }
      }
    }
    return false
  }
}
