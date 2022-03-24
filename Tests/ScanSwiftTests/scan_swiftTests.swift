import XCTest

@testable import ScanSwift

func p<T>(_ x: UnsafeMutablePointer<T>) -> Any {
    return x
}
final class scan_swiftTests: XCTestCase {
    func testExample() throws {
        var (s, a, b) = ("", 0, 0)
        let n = try sscan(content: "hello     2345  111", p(&s), p(&a), p(&b))
        XCTAssertEqual(n, 3)
        XCTAssertEqual(s, "hello")
        XCTAssertEqual(a, 2345)
        XCTAssertEqual(b, 111)
    }

    func testBufferReaderReadData() throws {
        let r = BufferCharReader(stringReader("hello, world"), size: 10)
        XCTAssertEqual("hello", String(data: r.readData(ofLength: 5), encoding: .utf8)!)
        XCTAssertEqual(", wor", String(data: r.readData(ofLength: 1000), encoding: .utf8)!)
        XCTAssertEqual("ld", String(data: r.readData(ofLength: 1000), encoding: .utf8)!)
        XCTAssertEqual(0, r.readData(ofLength: 1000).count)
    }

    func testBufferCharReaderReadCharAscii() throws {
        let r = BufferCharReader(stringReader("hello"), size: 3)
        XCTAssertEqual(Character("h"), r.readChar()!)
        XCTAssertEqual(Character("e"), r.readChar()!)
        XCTAssertEqual(Character("l"), r.readChar()!)
        XCTAssertEqual(Character("l"), r.readChar()!)
        XCTAssertEqual(Character("o"), r.readChar()!)
        XCTAssertNil(r.readChar())
    }

    func testBufferCharReaderReadCharMultiByte() throws {
        let s = stringReader("こんにちは")
        let r = BufferCharReader(s, size: 4)
        XCTAssertEqual(Character("こ"), r.readChar()!)
        XCTAssertEqual(Character("ん"), r.readChar()!)
        XCTAssertEqual(Character("に"), r.readChar()!)
        XCTAssertEqual(Character("ち"), r.readChar()!)
        XCTAssertEqual(Character("は"), r.readChar()!)
        XCTAssertNil(r.readChar())
    }

    func testFscanWithBufferCharReader() throws {
        var (s, a, b) = ("", 0, 0)
        let sr = stringReader("hello     2345  111")
        let r = BufferCharReader(sr, size: 100)
        let n = try fscan(f: r, p(&s), p(&a), p(&b))
        XCTAssertEqual(3, n)
        XCTAssertEqual(s, "hello")
        XCTAssertEqual(a, 2345)
        XCTAssertEqual(b, 111)
    }
}
