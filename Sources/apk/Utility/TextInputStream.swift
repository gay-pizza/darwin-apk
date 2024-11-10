/*
 * darwin-apk © 2024 Gay Pizza Specifications
 * SPDX-License-Identifier: Apache-2.0
 */

//FIXME: I don't like this, also SLOWWW
struct TextInputStream<InStream: InputStream> where InStream.Element == UInt8 {
  private var _stream: InStream

  public init(binaryStream: InStream) {
    _stream = binaryStream
  }

  public var lines: LineSequence {
    LineSequence(_stream: self._stream)
  }

  public struct LineSequence: Sequence {
    public typealias Element = String

    fileprivate var _stream: InStream

    public struct Iterator: IteratorProtocol where InStream.Element == UInt8 {
      public typealias Element = String

      fileprivate init(stream: InStream) {
        self._stream = stream
      }

      private var _stream: InStream
      private var _utf8Decoder = UTF8()
      private var _scalars = [Unicode.Scalar]()
      private var _lastChar: UnicodeScalar = "\0"
      private var _eof = false

      private mutating func decodeScalarsLine() {
        Decode: while true {
          switch self._utf8Decoder.decode(&self._stream) {
          case .scalarValue(let value):
            if value == "\n" {
              if self._lastChar == "\n" { break }
              else { break Decode }
            } else if value == "\r" {
              break Decode
            }
            self._scalars.append(value)
            self._lastChar = value
          case .emptyInput:
            self._eof = true
            break Decode
          case .error:
            break Decode
            //FIXME: repair like the stdlib does
            //scalars.append(UTF8.encodedReplacementCharacter)
            //lastChar = UTF8.encodedReplacementCharacter
          }
        }
      }

      public mutating func next() -> String? {
        // Return early if we already hit the end of the stream
        guard !self._eof else {
          return nil
        }

        // Decode a line of scalars
        self.decodeScalarsLine()
        defer {
          self._scalars.removeAll(keepingCapacity: true)
        }

        // Ignore the final empty newline
        guard !self._eof || !self._scalars.isEmpty else {
          return nil
        }

        // Convert to string and return
        var string = String()
        string.unicodeScalars.append(contentsOf: self._scalars)
        return string
      }
    }

    public func makeIterator() -> Iterator {
      Iterator(stream: self._stream)
    }
  }
}
