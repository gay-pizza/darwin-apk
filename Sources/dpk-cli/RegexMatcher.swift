/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser

struct RegexMatcher: PatternMatcher {
  private let _patterns: [Regex<_StringProcessing.AnyRegexOutput>]

  init(patterns: [String], ignoreCase: Bool) throws(ExitCode) {
    do {
      self._patterns = try patterns.map(Regex.init)
    } catch {
      print("Bad pattern \(error.localizedDescription)")
      throw .validationFailure
    }
  }

  func match(_ field: String) -> Bool {
    for pattern in self._patterns {
      if (try? pattern.firstMatch(in: field)) != nil {
        return true
      }
    }
    return false
  }
}
