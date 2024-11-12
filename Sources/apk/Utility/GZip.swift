/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import zlib

struct GZipReader: ~Copyable {
  private static let bufferSize = 0x8000

  private var zstream = z_stream()
  private var inputBuffer = [UInt8](repeating: 0, count: Self.bufferSize)
  private var outputBuffer = [UInt8](repeating: 0, count: Self.bufferSize)

  deinit {
    var zstream = self.zstream
    inflateEnd(&zstream)
  }

  mutating func read(inStream stream: inout any InputStream) throws(GZipError) -> Data {
    // Initialise zlib if this is the first time we're called
    // otherwise reset the stream in anticipation of reading the next concatenated stream
    var zerr = if self.zstream.state == nil {
      inflateInit2_(&self.zstream, 16 + MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
    } else {
      inflateReset(&self.zstream)
    }
    guard zerr == Z_OK else {
      throw .zlib(zerr)
    }

    var payload = Data()
    repeat {
      if self.zstream.avail_in == 0 {
        // Zlib has asked for more input, fill the input buffer
        let read: Int
        do {
          read = try stream.read(&inputBuffer, maxLength: inputBuffer.count)
        } catch {
          throw .streamError(error)
        }
        guard read > 0 else {
          throw .truncatedStream
        }

        // Reset input buffer read state
        self.zstream.avail_in = UInt32(read)
        self.zstream.next_in = inputBuffer.withUnsafeMutableBufferPointer(\.baseAddress!)
      }

      // Inflate next chunk of stream
      self.zstream.avail_out = UInt32(outputBuffer.count)
      self.zstream.next_out = outputBuffer.withUnsafeMutableBufferPointer(\.baseAddress!)
      zerr = inflate(&self.zstream, Z_NO_FLUSH)

      // Copy output bytes to payload
      let decodedBytes = outputBuffer.count - Int(self.zstream.avail_out)
      payload += Data(outputBuffer[..<decodedBytes])

    } while zerr == Z_OK
    guard zerr == Z_STREAM_END else {
      throw .zlib(zerr)
    }

    return payload
  }
}

enum GZipError: LocalizedError {
  case truncatedStream
  case streamError(_ err: StreamError)
  case zlib(_ err: Int32)

  var errorDescription: String? {
    switch self {
    case .truncatedStream:      "Reached end-of-stream before decoding finished"
    case .streamError(let err): "Underlying stream error: \(err.localizedDescription)"
    case .zlib(let err):        "zlib error \(err)"
    }
  }
}
