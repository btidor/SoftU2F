//
//  JSONKeyTests.swift
//  U2FTouchID
//

import XCTest
@testable import SoftU2FTool

class JSONKeyTests: XCTestCase {
    func testString() throws {
        let raw = "{\"key1\":\"value\",\"key3\":123}".data(using: .utf8)!
        let object = try JSONSerialization.jsonObject(with: raw) as! [String: Any?]
        
        let result = try JSONKey.string(object, "key1")
        XCTAssertEqual("value", result)
        
        XCTAssertThrowsError(try JSONKey.string(object, "key2"))
        XCTAssertThrowsError(try JSONKey.string(object, "key3"))
    }
    
    func testInt() throws {
        let raw = "{\"key1\":123,\"key3\":\"value\"}".data(using: .utf8)!
        let object = try JSONSerialization.jsonObject(with: raw) as! [String: Any?]
        
        let result = try JSONKey.int(object, "key1")
        XCTAssertEqual(123, result)
        
        XCTAssertThrowsError(try JSONKey.int(object, "key2"))
        XCTAssertThrowsError(try JSONKey.int(object, "key3"))
    }
    
    func testWebSafeBase64() throws {
        let raw = "{\"key1\":\"_-8AEg\",\"key3\":\"value\"}".data(using: .utf8)!
        let object = try JSONSerialization.jsonObject(with: raw) as! [String: Any?]
        
        let result = try JSONKey.webSafeBase64(object, "key1")
        let expected = Data(bytes: [0xff, 0xef, 0x00, 0x12])
        XCTAssertEqual(expected, result)
        
        XCTAssertThrowsError(try JSONKey.int(object, "key2"))
        XCTAssertThrowsError(try JSONKey.int(object, "key3"))
    }
    
    func testArray() throws {
        let raw = "{\"key1\":[{\"a\":1,\"b\":\"value\"}],\"key3\":\"value\"}".data(using: .utf8)!
        let object = try JSONSerialization.jsonObject(with: raw) as! [String: Any?]
        
        let result = try JSONKey.array(object, "key1")
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(1, try JSONKey.int(result[0], "a"))
        XCTAssertEqual("value", try JSONKey.string(result[0], "b"))
        
        XCTAssertThrowsError(try JSONKey.array(object, "key2"))
        XCTAssertThrowsError(try JSONKey.array(object, "key3"))
    }
}
