/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

struct ApkIndexInstallIf: ApkIndexRequirementRef {
  let name: String
  let versionSpec: ApkVersionSpecification

  init(name: String, version spec: ApkVersionSpecification) {
    self.name = name
    self.versionSpec = spec
  }
}
