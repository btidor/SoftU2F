//
//  HelperProtocol.swift
//  U2FTouchID
//
//  Created by btidor on 7/9/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation

class EnrollHelperRequest {
    let TYPE = "enroll_helper_request"
    
    let version: String
    let enrollChallenges: [EnrollChallenge]
    let signChallenges: [SignChallenge]
    
    init(json: [String: Any?]) throws {
        guard try JSONUtils.string(json, "type") == TYPE else {
            throw SerializationError.typeMismatch
        }
        
        version = try JSONUtils.string(json, "version")
        enrollChallenges = try JSONUtils.array(json, "enrollChallenges").map {
            try EnrollChallenge($0)
        }
        signChallenges = try JSONUtils.array(json, "signData").map {
            try SignChallenge($0)
        }
    }
}

class EnrollHelperReply {
    let TYPE = "enroll_helper_reply"
    
    let code: DeviceStatusCode
    let version: String
    let data: Data
    
    init(code: DeviceStatusCode, version: String, data: Data) {
        self.code = code
        self.version = version
        self.data = data
    }
    
    func dump() -> [String: Any] {
        return [
            "type": TYPE,
            "code": code,
            "version": version,
            "enrollData": data,
        ]
    }
}

class SignHelperRequest {
    let TYPE = "sign_helper_request"
    
    let version: String
    let signChallenges: [SignChallenge]
    
    init(json: [String: Any?]) throws {
        guard try JSONUtils.string(json, "type") == TYPE else {
            throw SerializationError.typeMismatch
        }
        
        version = try JSONUtils.string(json, "version")
        signChallenges = try JSONUtils.array(json, "signData").map {
            try SignChallenge($0)
        }
    }
}

class SignHelperReply {
    let TYPE = "sign_helper_reply"
    
    let code: DeviceStatusCode
    let error: String?
    let signChallenge: SignChallenge?
    let data: Data?
    
    init(signChallenge: SignChallenge, data: Data) {
        self.code = DeviceStatusCode.OK
        self.error = nil
        self.signChallenge = signChallenge
        self.data = data
    }
    
    init(code: DeviceStatusCode, error: String) {
        self.code = code
        self.error = error
        self.signChallenge = nil
        self.data = nil
    }
    
    func dump() -> [String: Any?] {
        var json: [String: Any?] = [
            "type": TYPE,
            "code": code,
            "errorDetail": error,
            "responseData": nil,
        ]
        
        if data != nil {
            json["responseData"] = [
                "version": signChallenge!.version,
                "appIdHash": signChallenge!.applicationParameter,
                "challengeHash": signChallenge!.challengeParameter,
                "keyHandle": signChallenge!.keyHandle,
                "signatureData": data!,
            ]
        }
        return json
    }
}

class EnrollChallenge {
    let version: String
    let challengeParameter: Data
    let applicationParameter: Data
    
    init(_ json: [String: Any?]) throws {
        version = try JSONUtils.string(json, "version")
        challengeParameter = try JSONUtils.webSafeBase64(json, "challengeHash")
        applicationParameter = try JSONUtils.webSafeBase64(json, "appIdHash")
    }
}

class SignChallenge {
    let version: String
    let challengeParameter: Data
    let applicationParameter: Data
    let keyHandle: Data
    
    init(_ json: [String: Any?]) throws {
        version = try JSONUtils.string(json, "version")
        challengeParameter = try JSONUtils.webSafeBase64(json, "challengeHash")
        applicationParameter = try JSONUtils.webSafeBase64(json, "appIdHash")
        keyHandle = try JSONUtils.webSafeBase64(json, "keyHandle")
    }
}

enum DeviceStatusCode: Int {
    // From devicestatuscodes.js
    case OK = 0
    case WRONG_LENGTH = 0x6700
    case WAIT_TOUCH = 0x6985
    case INVALID_DATA = 0x6984
    case WRONG_DATA = 0x6a80
    case TIMEOUT = -5
    case BUSY = -6
    case GONE = -8
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any?)
    case typeMismatch
}

private class JSONUtils {
    static func string(_ json: [String: Any?], _ key: String) throws -> String {
        guard let value = json[key] else {
            throw SerializationError.missing(key)
        }
        guard let typedValue = value as? String else {
            throw SerializationError.invalid(key, value)
        }
        return typedValue
    }
    
    static func webSafeBase64(_ json: [String: Any?], _ key: String) throws -> Data {
        let stringValue = try string(json, key)
        guard let decodedValue = WebSafeBase64.decode(stringValue) else {
            throw SerializationError.invalid(key, stringValue)
        }
        return decodedValue
    }
    
    static func array(_ json: [String: Any?], _ key: String) throws -> [[String: Any?]] {
        guard let value = json[key] else {
            throw SerializationError.missing(key)
        }
        guard let typedValue = value as? [[String: Any]] else {
            throw SerializationError.invalid(key, value)
        }
        return typedValue
    }
}
