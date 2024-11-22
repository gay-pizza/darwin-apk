/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

public struct ApkIndexProvides: Hashable, Sendable {
  let name: String

  init(requirement: ApkVersionRequirement) {
    self.name = requirement.name
  }
}
