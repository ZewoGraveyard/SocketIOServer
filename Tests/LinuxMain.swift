#if os(Linux)

import XCTest
@testable import SocketIOServerTestSuite

XCTMain([
  testCase(SocketIOServerTests.allTests),
])
#endif
