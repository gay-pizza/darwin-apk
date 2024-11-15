/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

public struct ApkIndexProvides: Hashable {
  let name: String

  init(requirement: ApkRequirement) {
    self.name = requirement.name
  }
}
