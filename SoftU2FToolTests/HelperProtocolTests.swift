//
//  HelperProtocolTests.swift
//  TouchIDU2F
//
//  Created by btidor on 7/15/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import XCTest

@testable import SoftU2FTool
class HelperProtocolTests: XCTestCase {
    func testDecodeEnrollRequest() throws {
        do {
            let string = "{\"type\":\"enroll_helper_request\",\"enrollChallenges\":[{\"version\":\"U2F_V2\",\"challengeHash\":\"CrUWUr1zhJ7vHADve0zFRP4dj_6m1d8yavzpYnskaWc\",\"appIdHash\":\"Nn22p8CXY3FE2ZNBDYrkKOGb_yHiovLCsagf5DTzsQ4\"}],\"signData\":[],\"timeout\":29,\"timeoutSeconds\":29}"
            let json = try JSONSerialization.jsonObject(with: string.data(using: .utf8)!) as! [String: Any]
            let request = try EnrollHelperRequest(json: json)
            XCTAssertEqual(1, request.enrollChallenges.count)
            XCTAssertEqual("U2F_V2", request.enrollChallenges[0].version)
            XCTAssertEqual("Nn22p8CXY3FE2ZNBDYrkKOGb_yHiovLCsagf5DTzsQ4",
                           WebSafeBase64.encode(request.enrollChallenges[0].applicationParameter))
            XCTAssertEqual("CrUWUr1zhJ7vHADve0zFRP4dj_6m1d8yavzpYnskaWc",
                           WebSafeBase64.encode(request.enrollChallenges[0].challengeParameter))
        } catch let err as SerializationError {
            dump(err)
            throw err
        }
    }
    
    func testEncodeEnrollReply() throws {
        let reply = EnrollHelperReply(code: DeviceStatusCode.OK, version: "U2F_V2", data: "TEST".data(using: .utf8)!)
        let string = String(data: try JSONSerialization.data(withJSONObject: reply.dump()), encoding: .utf8)!
        XCTAssertNotNil(string.range(of: "\"version\":\"U2F_V2\""))
        XCTAssertNotNil(string.range(of: "\"enrollData\":\"VEVTVA\""))
        XCTAssertNotNil(string.range(of: "\"type\":\"enroll_helper_reply\""))
        XCTAssertNotNil(string.range(of: "\"code\":0"))
    }
    
    func testDecodeSignRequest() throws {
        do {
            let string = "{\"type\":\"sign_helper_request\",\"signData\":[{\"challengeHash\":\"X1dDROpdXmAIgQHOWR-MnVuWKg0KOn-TFPK9dH4pa44\",\"appIdHash\":\"Nn22p8CXY3FE2ZNBDYrkKOGb_yHiovLCsagf5DTzsQ4\",\"keyHandle\":\"lZuoMIhpsC-T7ZTd-kdqG55zdUYnxWeqkwUnUrabmLI8GA-2fTniAGlX993b7nq5qgCp6nuzazTPtV5D-wAXow\",\"version\":\"U2F_V2\"}],\"timeout\":28.5,\"timeoutSeconds\":28.5}"
            let json = try JSONSerialization.jsonObject(with: string.data(using: .utf8)!) as! [String: Any]
            let request = try SignHelperRequest(json: json)
            XCTAssertEqual(1, request.signChallenges.count)
            XCTAssertEqual("U2F_V2", request.signChallenges[0].version)
            XCTAssertEqual("X1dDROpdXmAIgQHOWR-MnVuWKg0KOn-TFPK9dH4pa44",
                           WebSafeBase64.encode(request.signChallenges[0].challengeParameter))
            XCTAssertEqual("Nn22p8CXY3FE2ZNBDYrkKOGb_yHiovLCsagf5DTzsQ4",
                           WebSafeBase64.encode(request.signChallenges[0].applicationParameter))
            XCTAssertEqual("lZuoMIhpsC-T7ZTd-kdqG55zdUYnxWeqkwUnUrabmLI8GA-2fTniAGlX993b7nq5qgCp6nuzazTPtV5D-wAXow",
                           WebSafeBase64.encode(request.signChallenges[0].keyHandle))
        } catch let err as SerializationError {
            dump(err)
            throw err
        }
    }
    
    func testEncodeSignReplyError() throws {
        let reply = SignHelperReply(code: DeviceStatusCode.BUSY, error: "TEST")
        let string = String(data: try JSONSerialization.data(withJSONObject: reply.dump()), encoding: .utf8)!
        XCTAssertNotNil(string.range(of: "\"responseData\":null"))
        XCTAssertNotNil(string.range(of: "\"errorDetail\":\"TEST\""))
        XCTAssertNotNil(string.range(of: "\"type\":\"sign_helper_reply\""))
        XCTAssertNotNil(string.range(of: "\"code\":-6"))    }
    
    func testEncodeSignReplyOK() throws {
        let s = "{\"type\":\"sign_helper_request\",\"signData\":[{\"challengeHash\":\"X1dDROpdXmAIgQHOWR-MnVuWKg0KOn-TFPK9dH4pa44\",\"appIdHash\":\"Nn22p8CXY3FE2ZNBDYrkKOGb_yHiovLCsagf5DTzsQ4\",\"keyHandle\":\"lZuoMIhpsC-T7ZTd-kdqG55zdUYnxWeqkwUnUrabmLI8GA-2fTniAGlX993b7nq5qgCp6nuzazTPtV5D-wAXow\",\"version\":\"U2F_V2\"}],\"timeout\":28.5,\"timeoutSeconds\":28.5}"
        let json = try JSONSerialization.jsonObject(with: s.data(using: .utf8)!) as! [String: Any]
        let request = try SignHelperRequest(json: json)
        
        let reply = SignHelperReply(signChallenge: request.signChallenges[0], data: "TEST".data(using: .utf8)!)
        let string = String(data: try JSONSerialization.data(withJSONObject: reply.dump()), encoding: .utf8)!
        XCTAssertNotNil(string.range(of: "\"version\":\"U2F_V2\""))
        XCTAssertNotNil(string.range(of: "\"signatureData\":\"VEVTVA\""))
        XCTAssertNotNil(string.range(of: "\"keyHandle\":\"lZuoMIhpsC-T7ZTd-kdqG55zdUYnxWeqkwUnUrabmLI8GA-2fTniAGlX993b7nq5qgCp6nuzazTPtV5D-wAXow\""))
        XCTAssertNotNil(string.range(of: "\"appIdHash\":\"Nn22p8CXY3FE2ZNBDYrkKOGb_yHiovLCsagf5DTzsQ4\""))
        XCTAssertNotNil(string.range(of: "\"challengeHash\":\"X1dDROpdXmAIgQHOWR-MnVuWKg0KOn-TFPK9dH4pa44\""))
        XCTAssertNotNil(string.range(of: "\"errorDetail\":null"))
        XCTAssertNotNil(string.range(of: "\"type\":\"sign_helper_reply\""))
        XCTAssertNotNil(string.range(of: "\"code\":0"))
    }
}
