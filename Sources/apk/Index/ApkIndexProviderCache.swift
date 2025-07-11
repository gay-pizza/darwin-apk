/*
 * darwin-apk © 2025 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndexProviderCache {
  private var _providers = [(ApkIndexProvides, ApkIndex.Index)]()
  //private var _installIfCache = [(ApkIndexInstallIf, Set<ApkIndex.Index>)]()

  public init(index pkgIndex: ApkIndex) {
    for (index, pkg) in pkgIndex.packages.enumerated() {
      self._providers.append((.specific(name: pkg.name, version: pkg.version), index))
      for provision in pkg.provides {
        self._providers.append((provision, index))
      }
      //for installIf in pkg.installIf {
      //  self._installIfCache.append((installIf, index))
      //}
    }
  }
}

extension ApkIndexProviderCache {
  func resolve(index pkgIndex: ApkIndex, requirement: ApkVersionRequirement) -> ApkIndex.Index? {
    self._providers.filter { prv in prv.0.satisfies(requirement) }
      .max { pkgIndex.packages[$0.1] < pkgIndex.packages[$1.1] }?.1
  }
}

extension ApkIndexPackage: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    // Prefer highest declared provider priority
    lhs.providerPriority ?? 0 < rhs.providerPriority ?? 0
  }
}
