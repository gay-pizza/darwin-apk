/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import ArgumentParser

protocol PatternMatcher {
  init(patterns: [String], ignoreCase: Bool) throws(ExitCode)
  func match(_ field: String) -> Bool
}
