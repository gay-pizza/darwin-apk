/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import Darwin

public struct ApkVersionCompare {
  @inlinable public static func validate(_ version: String) -> Bool {
    Self.validate(ContiguousArray(version.utf8))
  }

  public static func validate(_ version: ContiguousArray<UInt8>) -> Bool {
    var reader = ApkVersionReader(version[...])
    while true {
      switch try? reader.next() {
      case .end: return true
      case nil:  return false
      default:   continue
      }
    }
  }

  @inlinable public static func compare(_ a: String, _ b: String, mode: Mode = .normal) -> Comparison? {
    Self.compare(ContiguousArray(a.utf8), ContiguousArray((b.utf8)), mode: mode)
  }

  public static func compare(_ a: ContiguousArray<UInt8>, _ b: ContiguousArray<UInt8>, mode: Mode = .normal) -> Comparison? {
    if (a.isEmpty && b.isEmpty) || a == b {
      return .equal
    }

    var readA = ApkVersionReader(a[...]), readB = ApkVersionReader(b[...])
    var tokenA: ApkVersionReader.TokenPart, tokenB: ApkVersionReader.TokenPart
    do {
      while true {
        (tokenA, tokenB) = (try readA.next(), try readB.next())
        guard let c = ApkVersionReader.TokenPart.compare(tokenA, tokenB) else {
          break
        }
        if c != .equal {
          return c
        }
      }
    } catch {
      return nil
    }

    // Both versions are equal if they're the same length or we are fuzzy matching prefixes
    if tokenA == tokenB || (mode == .fuzzy && tokenB == .end) {
      return .equal
    }

    // Mark non-prerelease versions as greater than the same version marked prerelease
    if case .suffix(let suffix) = tokenA, [ .alpha, .beta, .pre, .rc ].contains(suffix) {
      return .less
    } else if case .suffix(let suffix) = tokenB, [ .alpha, .beta, .pre, .rc ].contains(suffix) {
      return .greater
    } else {
      return ApkVersionReader.TokenPart.compValue(tokenB, tokenA)
    }
  }
}

public extension ApkVersionCompare {
  enum Comparison {
    case less, greater, equal
  }

  enum Mode {
    case normal, fuzzy
  }
}

//MARK: - Comparison implementation

fileprivate extension ApkVersionReader.TokenPart {
  static func compare(_ a: Self, _ b: Self) -> ApkVersionCompare.Comparison? {
    switch a {
    case .digit(let lhsNumber, let lhsString):
      guard case .digit(let rhsNumber, let rhsString) = b else {
        return nil
      }
      // If either are digit & zero prefixed & not initial then handle as string
      return if lhsString?.first == UInt8(ascii: "0") || rhsString?.first == UInt8(ascii: "0") {
        self.compValue(lhsString!, rhsString!)
      } else {
        Self.compValue(lhsNumber, rhsNumber)
      }
    case .letter(let lhs):
      return if case .letter(let rhs) = b { Self.compValue(lhs, rhs) } else { nil }
    case .suffixNumber(let lhs):
      return if case .suffixNumber(let rhs) = b { Self.compValue(lhs, rhs) } else { nil }
    case .revision(let lhs):
      return if case .revision(let rhs) = b { Self.compValue(lhs, rhs) } else { nil }
    case .commitHash(let lhs):
      return if case .commitHash(let rhs) = b { Self.compValue(lhs, rhs) } else { nil }
    case .suffix(let lhs):
      return if case .suffix(let rhs) = b { Self.compValue(lhs.rawValue, rhs.rawValue) } else { nil }
    case .end:
      return nil
    }
  }

  //MARK: - Private comparison implementation

  static func compValue<T: Comparable>(_ a: T, _ b: T) -> ApkVersionCompare.Comparison {
    if a < b { .less }
    else if a == b { .equal }
    else { .greater }
  }

  private static func compValue(_ a: ArraySlice<UInt8>, _ b: ArraySlice<UInt8>) -> ApkVersionCompare.Comparison {
    let minLength = min(a.count, b.count)
    let comparison = a.withUnsafeBytes { ca in
      b.withUnsafeBytes { cb in
        memcmp(ca.baseAddress!, cb.baseAddress!, minLength)
      }
    }
    if comparison != 0 {
      return comparison < 0 ? .less : .greater
    } else {
      return Self.compValue(a.count, b.count)
    }
  }
}
