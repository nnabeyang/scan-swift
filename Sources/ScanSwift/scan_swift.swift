import Foundation

internal let UTF8_MAX = 4
internal let UTF8_ASCCI_MAX = 0x80
private let HUGE_WID = 1 << 30
private let sign = "+-"
public protocol IOReader {
    func readData(ofLength length: Int) -> Data
}
extension FileHandle: IOReader {}
public protocol CharReader {
    func readChar() -> Character?
}

public protocol CharScanner: CharReader {
    func unReadChar() throws
}

private protocol ScanState: CharScanner {
    func skipSpace()
}
internal class stringReader: IOReader {
    private var data: Data
    init(_ str: String) {
        self.data = str.data(using: .utf8)!
    }
    func readData(ofLength length: Int) -> Data {
        if data.count == 0 {
            return Data()
        }
        let n = min(data.count, length)
        let v = data.subdata(in: 0..<n)
        data = data.subdata(in: n..<data.count)
        return v
    }
}
private class charReader: CharScanner {
    private let reader: IOReader
    private var buf = [UInt8](repeating: UInt8(0), count: UTF8_MAX)  // used only inside readChar
    private var pending: Int  // number of bytes in pendingBuf; only > 0 for bad UTF-8
    private var pendingBuf = [UInt8](repeating: UInt8(0), count: UTF8_MAX)  // bytes left over
    private var peekChar: Int64
    private var utf8Decoder: UTF8
    init(reader: IOReader) {
        self.reader = reader
        self.pending = 0
        self.peekChar = Int64(-1)
        self.utf8Decoder = .init()
    }
    private func readByte() -> UInt8? {
        let a = reader.readData(ofLength: 1)
        guard let v = a.first else {
            return nil
        }
        return v
    }
    fileprivate func readChar() -> Character? {
        if peekChar >= 0 {
            let ch = Character(Unicode.Scalar(UInt32(peekChar))!)
            peekChar = ~peekChar
            return ch
        }
        guard let b = readByte() else {
            return nil
        }
        buf[0] = b
        if b < UTF8_ASCCI_MAX {
            peekChar = ~Int64(b)
            return Character(Unicode.Scalar(b))
        }
        var n: Int = 1
        Decode: while true {
            var bytesIterator = buf[0..<n].makeIterator()
            switch utf8Decoder.decode(&bytesIterator) {
            case .scalarValue(let v):
                peekChar = ~Int64(v.value)
                return Character(v)
            case .emptyInput:
                break Decode
            case .error:
                guard let b = readByte() else {
                    return nil
                }
                buf[n] = b
                n += 1
            }
        }
        return nil
    }
    fileprivate func unReadChar() throws {
        if peekChar >= 0 {
            throw NSError(
                domain: "scanning called unreadChar with no character available", code: -1, userInfo: nil)
        }
        peekChar = ~peekChar
    }
}

private func notSpace(_ ch: Character) -> Bool {
    return !ch.isWhitespace
}
private class ss: ScanState {
    var rs: CharScanner  // where to read input
    var buf: [Character] = []  // token accumulator
    var count: Int = 0  // characters consumed so far.
    var atEOF: Bool = false  // already read EOF
    init(_ r: IOReader) {
        if let rr = r as? CharScanner {
            self.rs = rr
        } else {
            self.rs = charReader(reader: r)
        }
    }

    fileprivate func readChar() -> Character? {
        guard let ch = rs.readChar() else {
            atEOF = true
            return nil
        }
        count += 1
        return ch
    }

    fileprivate func unReadChar() throws {
        try rs.unReadChar()
        atEOF = false
        count -= 1
    }
    fileprivate func skipSpace() {
        while true {
            guard let ch = getChar() else {
                return
            }
            if ch == "\r" && peek("\n") {
                continue
            }
            if !ch.isWhitespace {
                try! unReadChar()
                break
            }
        }
    }

    private func token(skipSpace: Bool, _ f: (Character) -> Bool) -> [Character] {
        if skipSpace {
            self.skipSpace()
        }
        while true {
            guard let ch = getChar() else {
                break
            }
            if !f(ch) {
                try! unReadChar()
                break
            }
            buf.append(ch)
        }
        return buf
    }

    private func getChar() -> Character? {
        return readChar()
    }

    private func consume(_ ok: String, accept: Bool) -> Bool {
        guard let ch = getChar() else {
            return false
        }
        if ok.contains(ch) {
            if accept {
                buf.append(ch)
            }
            return true
        }
        if accept {
            try! unReadChar()
        }
        return false
    }

    private func peek(_ ok: String) -> Bool {
        guard let ch = getChar() else {
            return false
        }
        try! unReadChar()
        return ok.contains(ch)
    }

    private func notEOF() throws {
        if getChar() == nil {
            throw NSError(domain: "EOF", code: -1, userInfo: nil)
        }
        try! unReadChar()
    }

    private func accept(_ ok: String) -> Bool {
        return consume(ok, accept: true)
    }

    private func scanNumber(digits: String) -> String? {
        while accept(digits) {

        }
        return String(buf)
    }

    private func scanInt() throws -> Int {
        skipSpace()
        try notEOF()
        _ = accept(sign)
        guard let tok = scanNumber(digits: "1234567890") else {
            throw NSError(domain: "bad unicode format", code: -1, userInfo: nil)
        }
        return Int(tok)!
    }

    private func convertString() throws -> String {
        skipSpace()
        try notEOF()
        return String(token(skipSpace: false, notSpace))
    }

    func doScan(_ args: [Any]) throws -> Int {
        var n = 0
        for arg in args {
            buf = []
            switch arg {
            case let v as UnsafeMutablePointer<Int>:
                v.pointee = try scanInt()
            case let v as UnsafeMutablePointer<String>:
                v.pointee = try convertString()
            default:
                throw NSError(domain: "unsupport type", code: -1, userInfo: nil)
            }
            n += 1
        }
        return n
    }
}

public func fscan(f: IOReader, _ a: Any...) throws -> Int {
    return try ss(f).doScan(a)
}

public func scan(_ a: Any...) throws -> Int {
    return try ss(FileHandle.standardInput).doScan(a)
}

public func sscan(content: String, _ a: Any...) throws -> Int {
    return try ss(stringReader(content)).doScan(a)
}
