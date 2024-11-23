/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

public struct ApkIndexDependency: Hashable, Sendable {
  let requirement: ApkVersionRequirement

  init(requirement: ApkVersionRequirement) {
    self.requirement = requirement
  }
}
