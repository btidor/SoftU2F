//
//  ChromeNativeMessagingTests.swift
//  U2FTouchID
//

import XCTest

@testable import SoftU2FTool
class ChromeNativeMessagingTests: XCTestCase {
    func testReceiveMessage() throws {
        class MockedChromeNativeMessaging: ChromeNativeMessaging {
            override internal class func readInt() -> UInt32 {
                return UInt32(7)
            }
            
            override internal class func readData(ofLength: Int) -> Data {
                XCTAssertEqual(7, ofLength)
                return "{\"a\":1}".data(using: .utf8)!
            }
        }
        
        let expected: [String: Any] = ["a": 1]
        let actual = try MockedChromeNativeMessaging.receiveMessage()
        XCTAssertEqual("\(expected)", "\(actual)")
    }
    
    func testReceiveMessageLargeInput() throws {
        class MockedChromeNativeMessaging: ChromeNativeMessaging {
            override internal class func readInt() -> UInt32 {
                return UInt32(9999999)
            }
        }
        XCTAssertThrowsError(try MockedChromeNativeMessaging.receiveMessage())
    }
    
    func testSendMessage() throws {
        class MockedChromeNativeMessaging: ChromeNativeMessaging {
            static var _accumulator = Data()
            override internal class func write(_ data: Data) {
                _accumulator.append(data)
            }
        }
        
        let object = ["a": 1]
        try MockedChromeNativeMessaging.sendMessage(object)
        
        let expected = "\u{07}\0\0\0{\"a\":1}"
        let actual = String(data: MockedChromeNativeMessaging._accumulator, encoding: .utf8)!
        XCTAssertEqual(expected, actual)
    }
}
