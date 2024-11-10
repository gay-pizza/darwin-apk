// SPDX-License-Identifier: Apache-2.0

import Foundation

struct ApkIndexPackage: Hashable {
  let indexChecksum: ApkIndexDigest
  let name: String
  let version: String
  let architecture: String?
  let packageSize: UInt64
  let installedSize: UInt64
  let packageDescription: String
  let url: String
  let license: String
  let origin: String?
  let maintainer: String?
  let buildTime: Date?
  let commit: String?
  let providerPriority: UInt16?
  let dependencies: [ApkIndexDependency]
  let provides: [ApkIndexProvides]
  let installIf: [ApkIndexInstallIf]

  var downloadFilename: String { "\(self.name)-\(version).apk" }

  //TODO: Implementation
  //lazy var semanticVersion: (Int, Int, Int) = (0, 0, 0)
}

extension ApkIndexPackage {
  init(raw rawEntry: ApkRawIndexEntry) throws(Self.ParseError) {
    // Required fields
    var indexChecksum: ApkIndexDigest? = nil
    var name: String? = nil
    var version: String? = nil
    var description: String? = nil
    var url: String? = nil
    var license: String? = nil
    var packageSize: UInt64? = nil
    var installedSize: UInt64? = nil

    var dependencies = [ApkIndexDependency]()
    var provides = [ApkIndexProvides]()
    var installIf = [ApkIndexInstallIf]()

    // Optional fields
    var architecture: String? = nil
    var origin: String? = nil
    var maintainer: String? = nil
    var buildTime: Date? = nil
    var commit: String? = nil
    var providerPriority: UInt16? = nil

    // Read all the raw records for this entry
    for record in rawEntry.fields {
      switch record.key {
      case "P":
        name = record.value
      case "V":
        version = record.value
      case "T":
        description = record.value
      case "U":
        url = record.value
      case "L":
        license = record.value
      case "A":
        architecture = record.value
      case "D":
        do { dependencies = try ApkIndexDependency.extract(record.value) }
        catch { throw .badValue(key: record.key) }
      case "C":
        guard let digest = ApkIndexDigest(decode: record.value) else {
          throw .badValue(key: record.key)
        }
        indexChecksum = digest
      case "S":
        guard let value = UInt64(record.value, radix: 10) else {
          throw .badValue(key: record.key)
        }
        packageSize = value
      case "I":
        guard let value = UInt64(record.value, radix: 10) else {
          throw .badValue(key: record.key)
        }
        installedSize = value
      case "p":
        do { provides = try ApkIndexProvides.extract(record.value) }
        catch { throw .badValue(key: record.key) }
      case "i":
        do { installIf = try ApkIndexInstallIf.extract(record.value) }
        catch { throw .badValue(key: record.key) }
      case "o":
        origin = record.value
      case "m":
        maintainer = record.value
      case "t":
        guard let timet = UInt64(record.value, radix: 10),
            let timetInterval = TimeInterval(exactly: timet) else {
          throw .badValue(key: record.key)
        }
        buildTime = Date(timeIntervalSince1970: timetInterval)
      case "c":
        commit = record.value
      case "k":
        guard let value = UInt64(record.value, radix: 10),
            (0..<UInt64(UInt16.max)).contains(value) else {
          throw .badValue(key: record.key)
        }
        providerPriority = UInt16(truncatingIfNeeded: value)
      case "F", "M", "R", "Z", "r", "q", "a", "s", "f":
        break // installed db entries
      default:
        // Safe to ignore
        guard record.key.isLowercase else {
          throw .badValue(key: record.key)
        }
      }
    }

    self.indexChecksum = try indexChecksum.unwrap(or: Self.ParseError.required(key: "C"))
    self.name = try name.unwrap(or: Self.ParseError.required(key: "P"))
    self.version = try version.unwrap(or: Self.ParseError.required(key: "V"))
    self.packageDescription = try description.unwrap(or: Self.ParseError.required(key: "T"))
    self.url = try url.unwrap(or: Self.ParseError.required(key: "U"))
    self.license = try license.unwrap(or: Self.ParseError.required(key: "L"))
    self.packageSize = try packageSize.unwrap(or: Self.ParseError.required(key: "S"))
    self.installedSize = try installedSize.unwrap(or: Self.ParseError.required(key: "I"))

    self.architecture = architecture
    self.origin = origin
    self.maintainer = maintainer
    self.buildTime = buildTime
    self.commit = commit
    self.providerPriority = providerPriority

    self.dependencies = dependencies
    self.provides = provides
    self.installIf = installIf
  }

  public enum ParseError: Error, LocalizedError {
    case badValue(key: Character)
    case unexpectedKey(key: Character)
    case required(key: Character)

    public var errorDescription: String? {
      switch self {
      case .badValue(let key):      "Bad value for key \"\(key)\""
      case .unexpectedKey(let key): "Unexpected key \"\(key)\""
      case .required(let key):      "Missing required key \"\(key)\""
      }
    }
  }
}

extension ApkIndexPackage: CustomStringConvertible {
  var description: String {
    var s = String()
    s += "index checksum: \(self.indexChecksum)\n"
    s += "name: --------- \(self.name)\n"
    s += "version: ------ \(self.version)\n"
    if let architecture = self.architecture {
    s += "architecture: - \(architecture)\n"
    }
    s += "package size: - \(self.packageSize) byte(s) (\(self.packageSize.formatted(.byteCount(style: .file))))\n"
    s += "installed size: \(self.installedSize) byte(s) (\(self.installedSize.formatted(.byteCount(style: .file))))\n"
    s += "description: -- \(self.packageDescription)\n"
    s += "url: ---------- \(self.url)\n"
    s += "license: ------ \(self.license)\n"
    if let origin = self.origin {
    s += "origin: ------- \(origin)\n"
    }
    if let maintainer = self.maintainer {
    s += "maintainer: --- \(maintainer)\n"
    }
    if let buildTime = self.buildTime {
    s += "build time: --- \(buildTime)\n"
    }
    if let commit = self.commit {
    s += "commit: ------- \(commit)\n"
    }
    if let providerPrio = self.providerPriority {
    s += "provider prio:  \(providerPrio)\n"
    }
    if !self.dependencies.isEmpty {
    s += "dependencies: - \(self.dependencies.map(String.init).joined(separator: " "))\n"
    }
    if !self.provides.isEmpty {
    s += "provides: ----- \(self.provides.map { $0.name }.joined(separator: " "))\n"
    }
    if !self.installIf.isEmpty {
    s += "install if: --- \(self.installIf.map { $0.name }.joined(separator: " "))\n"
    }
    return s
  }
}

fileprivate extension Optional {
  func unwrap<E: Error>(or error: @autoclosure () -> E) throws(E) -> Wrapped {
    switch self {
    case .some(let v):
      return v
    case .none:
      throw error()
    }
  }
}
