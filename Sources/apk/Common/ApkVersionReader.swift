/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

internal struct ApkVersionReader {
  var string: ArraySlice<UInt8>
  private var seen: TokenFlag, last: TokenFlag

  init(_ string: ArraySlice<UInt8>) {
    self.string = string
    self.seen = []
    self.last = []
  }

  mutating func next() throws(Invalid) -> TokenPart {
    self.seen.formUnion(self.last)

    switch string.first ?? UInt8(ascii: "0") {
    case UInt8(ascii: "a")...UInt8(ascii: "z"):  // Letter suffix
      guard self.seen.contains(.initial),
          self.last.isDisjoint(with: [ .letter, .suffix, .suffixNumber, .commitHash, .revision ]) else {
        throw .invalid
      }
      self.last = .letter
      return .letter(self.advance())
    case UInt8(ascii: "."):  // Version separator
      guard self.seen.contains(.initial), self.last.contains(.digit) else {
        throw .invalid
      }
      self.advance()
      fallthrough
    case UInt8(ascii: "0")...UInt8(ascii: "9"):  // Numeric component
      guard self.last.isSubset(of: [ .initial, .digit, .suffix ]),
          let (number, numString) = self.readNumber() else {
        throw .invalid
      }
      if self.last == .suffix {
        self.last = .suffixNumber
        return .suffixNumber(number)
      } else {
        self.last = .digit
        if !self.seen.contains(.initial) {
          self.last.insert(.initial)
          return .digit(number, nil)
        } else {
          // Numeric digits that aren't initial might be compared as a string instead
          return .digit(number, numString)
        }
      }
    case UInt8(ascii: "_"):  // Suffix
      guard self.seen.contains(.initial), self.seen.isDisjoint(with: [ .commitHash, .revision ]) else {
        throw .invalid
      }
      self.advance()
      guard let suffix = self.readVersionSuffix() else {
        throw .invalid
      }
      self.last = .suffix
      return .suffix(suffix)
    case UInt8(ascii: "~"):  // Commit hash
      guard self.seen.contains(.initial), self.seen.isDisjoint(with: [ .commitHash, .revision ]) else {
        throw .invalid
      }
      self.advance()
      let end = self.string.firstIndex(where: { !$0.isHexDigit }) ?? self.string.endIndex
      let hex = self.advance(end)
      guard self.string.isEmpty else {  // Commit hash should take the rest of string
        throw .invalid
      }
      self.last = .commitHash
      return .commitHash(hex)
    case UInt8(ascii: "-"):  // Package revision
      guard self.seen.contains(.initial), self.seen.isDisjoint(with: .revision),
          self.advance(2) == [ UInt8(ascii: "-"), UInt8(ascii: "r") ],
          let (number, _) = self.readNumber() else {
        throw .invalid
      }
      self .last = .revision
      return .revision(number)
    case UInt8(ascii: "\0"):  // End of version string
      guard self.seen.contains(.initial) else {
        throw .invalid
      }
      return .end
    default:
      throw .invalid
    }
  }

  //MARK: - Private Implementation

  private mutating func readNumber() -> (UInt, ArraySlice<UInt8>)? {
    let maxLength = self.string.count
    let (end, result) = self.string.withUnsafeBufferPointer {
      var i = 0, accum: UInt = 0
      while i < maxLength {
        let c = $0[i]
        if !(UInt8(ascii: "0")...UInt8(ascii: "9") ~= c) {
          break
        }
        accum = accum &* 10 &+ UInt(c - UInt8(ascii: "0"))
        i += 1
      }
      return (i, accum)
    }
    if end == 0 {
      return nil
    }
    return (result, self.advance(end))
  }

  private mutating func readVersionSuffix() -> VersionSuffix? {
    let end = self.string.firstIndex(where: { !(UInt8(ascii: "a")...UInt8(ascii: "z") ~= $0) }) ?? self.string.endIndex
    let suffix = self.advance(end - self.string.startIndex)
    return switch suffix.first {  // TODO: Should this matching be stricter?
    case UInt8(ascii: "a"): .alpha
    case UInt8(ascii: "b"): .beta
    case UInt8(ascii: "c"): .cvs
    case UInt8(ascii: "g"): .git
    case UInt8(ascii: "h"): .hg
    case UInt8(ascii: "p"): suffix.count == 1 ? .p : .pre
    case UInt8(ascii: "r"): .rc
    case UInt8(ascii: "s"): .svn
    default: nil
    }
  }

  @discardableResult
  private mutating func advance(_ len: Int) -> ArraySlice<UInt8> {
    let beg = self.string.startIndex
    let end = min(string.index(beg, offsetBy: len), string.endIndex)
    defer {
      self.string = self.string[end...]
    }
    return self.string[beg..<end]
  }

  @discardableResult
  private mutating func advance() -> UInt8 {
    defer {
      self.string = string[string.index(after: string.startIndex)...]
    }
    return self.string[self.string.startIndex]
  }
}

extension ApkVersionReader {
  private struct TokenFlag: OptionSet {
    let rawValue: UInt8

    static let initial      = Self(rawValue: 1 << 0)
    static let digit        = Self(rawValue: 1 << 1)
    static let letter       = Self(rawValue: 1 << 2)
    static let suffix       = Self(rawValue: 1 << 3)
    static let suffixNumber = Self(rawValue: 1 << 4)
    static let commitHash   = Self(rawValue: 1 << 5)
    static let revision     = Self(rawValue: 1 << 6)
  }

  enum TokenPart {
    case digit(_ number: UInt, _ string: ArraySlice<UInt8>?)
    case letter(_ char: UInt8)
    case suffix(_ suffix: VersionSuffix)
    case suffixNumber(_ number: UInt)
    case commitHash(_ hash: ArraySlice<UInt8>)
    case revision(_ number: UInt)
    case end
  }

  enum VersionSuffix: Int {
    case alpha = 0, beta = 1, cvs = 5, git = 7, hg = 8, pre = 2, p = 9, rc = 3, svn = 6
  }

  enum Invalid: Error {
    case invalid
  }
}

extension ApkVersionReader.TokenPart: Comparable {
  @inlinable var order: Int {
    switch self {
    case .digit:        1
    case .letter:       2
    case .suffix:       3
    case .suffixNumber: 4
    case .commitHash:   5
    case .revision:     6
    case .end:          7
    }
  }

  @inlinable static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.order == rhs.order
  }

  @inlinable static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.order < rhs.order
  }
}

fileprivate extension UInt8 {
  @inline(__always) var isHexDigit: Bool {
    switch self {
    case UInt8(ascii: "0")...UInt8(ascii: "9"),
         UInt8(ascii: "A")...UInt8(ascii: "F"),
         UInt8(ascii: "a")...UInt8(ascii: "f"):
     true
    default: false
    }
  }
}
