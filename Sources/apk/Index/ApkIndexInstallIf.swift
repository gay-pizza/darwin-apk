/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

struct ApkIndexInstallIf: Hashable {
  let requirement: ApkRequirement

  init(requirement: ApkRequirement) {
    self.requirement = requirement
  }
}
