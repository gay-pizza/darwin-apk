/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

public struct ApkIndexInstallIf: Hashable, Sendable {
  let requirement: ApkRequirement

  init(requirement: ApkRequirement) {
    self.requirement = requirement
  }
}
