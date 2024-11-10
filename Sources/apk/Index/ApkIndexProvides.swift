/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

struct ApkIndexProvides: ApkIndexRequirementRef {
  let name: String

  init(name: String, version _: ApkVersionSpecification) {
    self.name = name
  }
}
