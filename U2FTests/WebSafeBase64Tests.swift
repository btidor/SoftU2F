//
//  WebSafeBase64Tests.swift
//  U2FTouchID
//

import XCTest
@testable import U2F

class WebSafeBase64Tests: XCTestCase {
    func testRoundTrip() {
        for length in 0...10 {
            let orig = Data(repeating: 0x41, count: length)
            let encoded = WebSafeBase64.encode(orig)

            XCTAssertNil(encoded.characters.index(of: Character("+")))
            XCTAssertNil(encoded.characters.index(of: Character("/")))
            XCTAssertNil(encoded.characters.index(of: Character("=")))

            let decoded = WebSafeBase64.decode(encoded)
            XCTAssertNotNil(decoded)
            XCTAssertEqual(orig, decoded)
        }
    }
}
