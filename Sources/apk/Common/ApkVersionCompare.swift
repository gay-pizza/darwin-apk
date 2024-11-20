/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Darwin

public struct ApkVersionCompare {
  public static func validate(_ version: String) -> Bool {
    var reader = ApkVersionReader(version[...])
    while true {
      switch try? reader.next() {
      case .end: return true
      case nil:  return false
      default:   continue
      }
    }
  }

  public static func compare(_ a: String, _ b: String, mode: Mode = .normal) -> Comparison? {
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
      return if lhsString?.first == "0" || rhsString?.first == "0" {
        self.compValue(lhsString!, rhsString!)
      } else {
        Self.compValue(lhsNumber, rhsNumber)
      }
    case .letter(let lhs):
      guard case .letter(let rhs) = b else {
        return nil
      }
      return Self.compValue(lhs.isASCII ? UInt(lhs.asciiValue!) : 0, rhs.isASCII ? UInt(rhs.asciiValue!) : 0)
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

  private static func compValue<T: StringProtocol>(_ a: T, _ b: T) -> ApkVersionCompare.Comparison {
    let minLength = min(a.utf8.count, b.utf8.count)
    let comparison = a.withCString { ca in
      b.withCString { cb in
        memcmp(ca, cb, minLength)
      }
    }
    if comparison != 0 {
      return comparison < 0 ? .less : .greater
    } else {
      return Self.compValue(a.utf8.count, b.utf8.count)
    }
  }
}
