/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

struct ApkRawIndex {
  let packages: [ApkRawIndexEntry]

  init(lines: any Sequence<String>) throws {
    var packages = [ApkRawIndexEntry]()

    var recordLines = [String]()
    recordLines.reserveCapacity(15)

    for line in lines {
      if line.trimmingCharacters(in: .whitespaces).isEmpty {
        if !recordLines.isEmpty {
          packages.append(try .init(parsingEntryLines: recordLines))
          recordLines.removeAll(keepingCapacity: true)
        }
      } else {
        recordLines.append(line)
      }
    }
    if !recordLines.isEmpty {
      packages.append(try .init(parsingEntryLines: recordLines))
    }

    self.packages = packages
  }
}

struct ApkRawIndexEntry {
  let fields: [Record]

  struct Record {
    let key: Character
    let value: String
  }
}

extension ApkRawIndexEntry {
  init(parsingEntryLines lines: any Sequence<String>) throws {
    self.fields = try lines.map { line in
      guard let splitIdx = line.firstIndex(of: ":"),
          line.distance(from: line.startIndex, to: splitIdx) == 1 else {
        throw ApkRawIndexError.badPair
      }
      return Record(
        key:   line.first!,
        value: String(line[line.index(after: splitIdx)...]))
    }
  }

  func toMap() -> [Character: String] {
    Dictionary(uniqueKeysWithValues: self.fields.map { $0.pair })
  }

  func lookup(_ key: Character) -> String? {
    fields.first(where: { $0.key == key })?.value
  }
}

extension ApkRawIndexEntry.Record {
  var pair: (Character, String) {
    (self.key, self.value)
  }
}

enum ApkRawIndexError: Error, LocalizedError {
  case badPair

  var errorDescription: String? {
    switch self {
    case .badPair: "Malformed raw key-value pair"
    }
  }
}
