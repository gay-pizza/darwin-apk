/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

struct ApkIndexInstallIf: ApkIndexRequirementRef {
  let name: String
  let versionSpec: ApkVersionSpecification

  init(extract: String) throws(ApkRequirement.ParseError) {
    (self.name, self.versionSpec) = try ApkRequirement.extract(blob: extract)
  }
}
