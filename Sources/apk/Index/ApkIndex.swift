// SPDX-License-Identifier: Apache-2.0

struct ApkIndex {
  let packages: [ApkIndexPackage]
}

extension ApkIndex {
  func first(name: String) -> ApkIndexPackage? {
    self.packages.first {
      $0.name == name
    }
  }
}

extension ApkIndex {
  static func merge<S: Sequence>(_ tables: S) -> Self where S.Element == Self {
    Self.init(packages: tables.flatMap(\.packages))
  }

  static func merge(_ tables: Self...) -> ApkIndex {
    Self.init(packages: tables.flatMap(\.packages))
  }
}

extension ApkIndex {
  init(raw: ApkRawIndex) throws {
    self.packages = try raw.packages.map {
      try ApkIndexPackage(raw: $0)
    }
  }
}

extension ApkIndex: CustomStringConvertible {
  var description: String {
    self.packages.map(String.init).joined(separator: "\n")
  }
}
