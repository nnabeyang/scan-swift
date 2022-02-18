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
}
