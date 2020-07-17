import XCTest
@testable import Convertor

final class ConvertorTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Convertor().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
