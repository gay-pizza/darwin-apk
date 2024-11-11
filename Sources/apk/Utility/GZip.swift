/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import zlib

struct GZip {
  static let CM_DEFLATE: UInt8 = 8

  static let FTEXT: UInt8    = 1 << 0
  static let FHCRC: UInt8    = 1 << 1
  static let FEXTRA: UInt8   = 1 << 2
  static let FNAME: UInt8    = 1 << 3
  static let FCOMMENT: UInt8 = 1 << 4

  static let XFL_BEST: UInt8    = 2
  static let XFL_FASTEST: UInt8 = 4

  private static func skipString(_ stream: inout any InputStream) throws(GZipError) {
    var c: UInt8?
    repeat {
      c = stream.next()
      guard c != nil else {
        throw .truncatedStream
      }
    } while c != 0
  }

  static func read(inStream stream: inout any InputStream) throws(GZipError) -> Data {
    // Check Gzip magic signature
    guard (try? stream.read(2)) == Data([0x1F, 0x8B]) else {
      throw .badMagic
    }

    // Check compression field (should only ever be DEFLATE)
    guard let compression = stream.next(),
        compression == Self.CM_DEFLATE else {
      throw .badHeader
    }

    guard
        let flags = stream.next(),
        let modificationTime = stream.readUInt(),
        let extraFlags = stream.next(),
        let operatingSystemID = stream.next() else {
      throw .truncatedStream
    }


    if flags & Self.FEXTRA != 0 {
      // Skip "extra" field
      guard let extraLength = stream.readUShort() else {
        throw.truncatedStream
      }
      do {
        try stream.seek(.current(Int(extraLength)))
      } catch {
        throw .streamError(error)
      }
    }
    if flags & Self.FNAME != 0 {
      // Skip null-terminated name string
      try skipString(&stream)
    }
    if flags & Self.FCOMMENT != 0 {
      // Skip null-terminated comment string
      try skipString(&stream)
    }
    if flags & Self.FHCRC != 0 {
      guard let crc16 = stream.readUShort() else {
        throw .badField("crc16")
      }
    }

    let deflateBegin: Int
    do {
      deflateBegin = try stream.tell
    } catch {
      throw .streamError(error)
    }

    var payload = Data()
    let (streamLength, computedCRC) = try Self.deflate(payload: &payload, stream: &stream)

    // End-of-stream verification fields
    do {
      try stream.seek(.set(deflateBegin + streamLength))
    } catch {
      throw .streamError(error)
    }
    guard
        let crc = stream.readUInt(),
        let inputSizeMod32 = stream.readUInt() else {
      throw .truncatedStream
    }

    // Perform verification checks
    guard UInt32(truncatingIfNeeded: computedCRC) == crc else {
      throw .verificationFailed("CRC32 didn't match")
    }
    guard inputSizeMod32 == UInt32(truncatingIfNeeded: payload.count) else {
      throw .verificationFailed("Bad decompressed size")
    }

    return payload
  }

  private static func deflate(payload: inout Data, stream: inout any InputStream) throws(GZipError) -> (Int, UInt) {
    var zstream = z_stream()
    var zerr = inflateInit2_(&zstream, -15, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
    guard zerr == Z_OK else {
      throw .zlib(zerr)
    }

    defer {
      inflateEnd(&zstream)
    }

    let bufferSize = 0x8000
    var inputBuffer = [UInt8](repeating: 0, count: bufferSize)
    var outputBuffer = [UInt8](repeating: 0, count: bufferSize)

    var computeCRC: UInt = crc32(0, nil, 0)
    var block = 0
    repeat {
      if zstream.avail_in == 0 {
        let read: Int
        do {
          read = try stream.read(&inputBuffer, maxLength: inputBuffer.count)
        } catch {
          throw .streamError(error)
        }
        guard read > 0 else {
          throw .truncatedStream
        }
        zstream.avail_in = UInt32(read)
        zstream.next_in = inputBuffer.withUnsafeMutableBufferPointer(\.baseAddress!)
      }
      zstream.avail_out = UInt32(outputBuffer.count)
      zstream.next_out = outputBuffer.withUnsafeMutableBufferPointer(\.baseAddress!)
      zerr = inflate(&zstream, Z_BLOCK)

      let decodedBytes = outputBuffer.count - Int(zstream.avail_out)
      computeCRC = crc32(computeCRC, outputBuffer, UInt32(decodedBytes))
      payload += Data(outputBuffer[..<decodedBytes])
      block += decodedBytes

      if zstream.data_type & (1 << 7) != 0 {
        // At the end of a deflate block, we're done if it was empty
        if block == 0 {
          break
        }
        block = 0
      }
    } while zerr == Z_OK

    guard zerr == Z_STREAM_END else {
      throw .zlib(zerr)
    }

    return (Int(zstream.total_in), computeCRC)
  }
}

enum GZipError: LocalizedError {
  case streamError(_ err: StreamError)
  case verificationFailed(_ msg: String)
  case badMagic
  case badHeader
  case badField(_ name: String)
  case truncatedStream
  case zlib(_ err: Int32)

  var errorDescription: String? {
    switch self {
    case .verificationFailed(let msg): msg
    case .streamError(let err): "Underlying stream error: \(err.localizedDescription)"
    case .badMagic:             "Not a Gzip file"
    case .badHeader:            "Malformed Gzip header"
    case .badField(let name):   "Bad Gzip \(name) field"
    case .truncatedStream:      "Reached end-of-stream before decoding finished"
    case .zlib(let err):        "zlib error \(err)"
    }
  }
}

fileprivate extension InputStream {
  mutating func readUShort() -> UInt16? {
    guard let buffer = try? self.read(2), buffer.count == 2 else {
      return nil
    }
    return buffer.withUnsafeBytes { $0.load(as: UInt16.self) }.littleEndian
  }

  mutating func readUInt() -> UInt32? {
    guard let buffer = try? self.read(4), buffer.count == 4 else {
      return nil
    }
    return buffer.withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
  }
}
