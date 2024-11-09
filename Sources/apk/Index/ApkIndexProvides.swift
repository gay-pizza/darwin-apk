// SPDX-License-Identifier: Apache-2.0

struct ApkIndexProvides: ApkIndexRequirementRef {
  let name: String

  init(extract: String) throws(ApkRequirement.ParseError) {
    (self.name, _) = try ApkRequirement.extract(blob: extract)
  }
}
