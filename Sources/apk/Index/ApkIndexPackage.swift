/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public struct ApkIndexPackage: Hashable, Sendable {
  public let indexChecksum: ApkIndexDigest
  public let name: String
  public let version: String
  public let architecture: String?
  public let packageSize: UInt64
  public let installedSize: UInt64
  public let packageDescription: String
  public let url: String
  public let license: String
  public let origin: String?
  public let maintainer: String?
  public let buildTime: Date?
  public let commit: String?
  public let providerPriority: UInt16?
  public let dependencies: [ApkIndexDependency]
  public let provides: [ApkIndexProvides]
  public let installIf: [ApkIndexInstallIf]

  public var downloadFilename: String { "\(self.name)-\(version).apk" }

  init(name: String, version spec: ApkVersionSpecification) {
    fatalError("Cannot construct an ApkIndexPackage this way")
  }
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
        do {
          dependencies = try record.value.split(separator: " ")
            .map { .init(requirement: try .init(extract: $0)) }
        } catch { throw .badValue(key: record.key, cause: error.localizedDescription) }
      case "C":
        guard let digest = ApkIndexDigest(decode: record.value) else {
          throw .badValue(key: record.key, cause: "Invalid SHA digest")
        }
        indexChecksum = digest
      case "S":
        guard let value = UInt64(record.value, radix: 10) else {
          throw .badValue(key: record.key, cause: "Invalid size value")
        }
        packageSize = value
      case "I":
        guard let value = UInt64(record.value, radix: 10) else {
          throw .badValue(key: record.key, cause: "Invalid installed size value")
        }
        installedSize = value
      case "p":
        do {
          provides = try record.value.split(separator: " ")
            .map { try .init(requirement: try .init(extract: $0)) }
        } catch { throw .badValue(key: record.key, cause: error.localizedDescription) }
      case "i":
        do {
          installIf = try record.value.split(separator: " ")
            .map { .init(requirement: try .init(extract: $0)) }
        } catch { throw .badValue(key: record.key, cause: error.localizedDescription) }
      case "o":
        origin = record.value
      case "m":
        maintainer = record.value
      case "t":
        guard let timet = UInt64(record.value, radix: 10),
            let timetInterval = TimeInterval(exactly: timet) else {
          throw .badValue(key: record.key, cause: "Invalid build time value")
        }
        buildTime = Date(timeIntervalSince1970: timetInterval)
      case "c":
        commit = record.value
      case "k":
        guard let value = UInt64(record.value, radix: 10),
            (0..<UInt64(UInt16.max)).contains(value) else {
          throw .badValue(key: record.key, cause: "Invalid provider priority value")
        }
        providerPriority = UInt16(truncatingIfNeeded: value)
      case "F", "M", "R", "Z", "r", "q", "a", "s", "f":
        break // installed db entries
      default:
        // Safe to ignore
        guard record.key.isLowercase else {
          throw .unexpectedKey(key: record.key)
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
    case badValue(key: Character, cause: String)
    case unexpectedKey(key: Character)
    case required(key: Character)

    public var errorDescription: String? {
      switch self {
      case .badValue(let key, let cause):  "Bad value for key \"\(key)\": \(cause)"
      case .unexpectedKey(let key):        "Unexpected key \"\(key)\""
      case .required(let key):             "Missing required key \"\(key)\""
      }
    }
  }
}

public extension ApkIndexPackage {
  var nameDescription: String {
    "\(self.name)-\(self.version) \(self.architecture ?? "")"
  }

  var shortDescription: String {
    "\(self.nameDescription)\n \\_ \(self.packageDescription)"
  }
}

extension ApkIndexPackage: CustomStringConvertible {
  public var description: String {
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
    s += "dependencies: - \(self.dependencies.map(\.requirement.description).joined(separator: " "))\n"
    }
    if !self.provides.isEmpty {
    s += "provides: ----- \(self.provides.map(\.description).joined(separator: " "))\n"
    }
    if !self.installIf.isEmpty {
    s += "install if: --- \(self.installIf.map(\.requirement.description).joined(separator: " "))\n"
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
