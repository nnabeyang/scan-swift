import Foundation

public class BufferCharReader: CharScanner, IOReader {
    private let rd: IOReader
    private let size: Int
    private var buf: Data
    private var r: Int
    private var w: Int
    private var lastCharSize: Int
    private var atEOF: Bool = false
    private var utf8Parser: UTF8.ForwardParser
    public init(_ rd: IOReader, size: Int) {
        self.rd = rd
        self.size = size
        self.buf = Data(count: size)
        self.r = 0
        self.w = 0
        self.lastCharSize = -1
        self.utf8Parser = .init()
    }
    private func fill() {
        if r > 0 {
            buf[0...(w - r)] = buf[r..<w]
            w -= r
            r = 0
        }
        let d = rd.readData(ofLength: size - w)
        if d.count < (size - w) {
            atEOF = true
        }
        buf[w...] = d
        w += d.count
    }
    public func readData(ofLength length: Int) -> Data {
        if length == 0 {
            return Data()
        }
        if r == w {
            if length >= size {
                lastCharSize = -1
                return rd.readData(ofLength: length)
            }
            r = 0
            w = 0
            let data = rd.readData(ofLength: size)
            if data.count == 0 {
                return Data()
            }
            buf[0..<data.count] = data
            w += data.count
        }
        let d = buf.subdata(in: r..<min(r + length, w))
        r += d.count
        lastCharSize = -1
        return d
    }
    public func readChar() -> Character? {
        if !atEOF && r + UTF8_MAX > w && (w - r) < size {
            fill()
        }
        lastCharSize = -1
        if r == w {
            return nil
        }
        if buf[r] >= UTF8_ASCCI_MAX {
            var bytesIterator = buf[r..<min(r + UTF8_MAX, buf.count)].makeIterator()
            switch utf8Parser.parseScalar(from: &bytesIterator) {
            case .valid(let v):
                _ = utf8Parser.parseScalar(from: &bytesIterator)
                let ch = Character(UTF8.decode(v))
                r += v.count
                return ch
            default:
                return nil
            }
        }
        let ch = Character(Unicode.Scalar(buf[r]))
        lastCharSize = 1
        r += 1
        return ch
    }
    public func unReadChar() throws {
        if lastCharSize < 0 || r < lastCharSize {
            throw NSError(domain: "invalid use of unReadChar", code: -1, userInfo: nil)
        }
        atEOF = false
        r -= lastCharSize
        lastCharSize = -1
    }
}
