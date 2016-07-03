import XCTest
@testable import SocketIOServer

class SocketIOServerTests: XCTestCase {
    func testReality() {
        XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
    }
}

extension SocketIOServerTests {
    static var allTests: [(String, (SocketIOServerTests) -> () throws -> Void)] {
        return [
           ("testReality", testReality),
        ]
    }
}
