/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

internal struct ApkVersionReader {
  var string: Substring
  private var seen: TokenFlag, last: TokenFlag

  init(_ string: Substring) {
    self.string = string
    self.seen = []
    self.last = []
  }

  mutating func next() throws(Invalid) -> TokenPart {
    self.seen.formUnion(self.last)

    switch string.first ?? "\0" {
    case "a"..."z":  // Letter suffix
      guard self.seen.contains(.initial),
          self.last.isDisjoint(with: [ .letter, .suffix, .suffixNumber, .commitHash, .revision ]) else {
        throw .invalid
      }
      self.last = .letter
      return .letter(self.advance())
    case ".":  // Version separator
      guard self.seen.contains(.initial), self.last.contains(.digit) else {
        throw .invalid
      }
      self.advance()
      fallthrough
    case "0"..."9":  // Numeric component
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
    case "_":  // Suffix
      guard self.seen.contains(.initial), self.seen.isDisjoint(with: [ .commitHash, .revision ]) else {
        throw .invalid
      }
      self.advance()
      guard let suffix = self.readVersionSuffix() else {
        throw .invalid
      }
      self.last = .suffix
      return .suffix(suffix)
    case "~":  // Commit hash
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
    case "-":  // Package revision
      guard self.seen.contains(.initial), self.seen.isDisjoint(with: .revision),
          self.advance(2) == "-r",
          let (number, _) = self.readNumber() else {
        throw .invalid
      }
      self .last = .revision
      return .revision(number)
    case "\0":  // End of version string
      guard self.seen.contains(.initial) else {
        throw .invalid
      }
      return .end
    default:
      throw .invalid
    }
  }

  //MARK: - Private Implementation

  private mutating func readNumber() -> (UInt, Substring)? {
    // Hacky and awful but seems to be the fastest way to get numeric token length
    let digits = self.string.withCString {
      var i = 0
      while 48...57 ~= $0[i] {  // isnumber(Int32($0[i])) != 0
        i += 1
      }
      return i
    }
    let end = self.string.index(self.string.startIndex, offsetBy: digits)
    let string = self.string[..<end]
    self.string = self.string[end...]
    guard !string.isEmpty, let result = UInt(string, radix: 10) else {
      return nil
    }
    return (result, string)
  }

  private mutating func readVersionSuffix() -> VersionSuffix? {
    let end = self.string.firstIndex(where: { !$0.isLowercase }) ?? self.string.endIndex
    let suffix = self.advance(end)
    return switch suffix.first {  // TODO: Should this matching be stricter?
    case "a": .alpha
    case "b": .beta
    case "c": .cvs
    case "g": .git
    case "h": .hg
    case "p": suffix.count == 1 ? .p : .pre
    case "r": .rc
    case "s": .svn
    default: nil
    }
  }

  @discardableResult
  private mutating func advance(_ next: String.Index) -> Substring {
    defer {
      self.string = self.string[next...]
    }
    return self.string[..<next]
  }

  @discardableResult
  private mutating func advance() -> Character {
    defer {
      self.string = string[string.index(after: string.startIndex)...]
    }
    return self.string[self.string.startIndex]
  }

  private mutating func advance(_ len: Int) -> Substring {
    self.advance(self.string.index(self.string.startIndex, offsetBy: len))
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
    case digit(_ number: UInt, _ string: Substring?)
    case letter(_ char: Character)
    case suffix(_ suffix: VersionSuffix)
    case suffixNumber(_ number: UInt)
    case commitHash(_ hash: Substring)
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
