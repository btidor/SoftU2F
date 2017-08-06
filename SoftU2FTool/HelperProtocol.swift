//
//  HelperProtocol.swift
//  U2FTouchID
//

import Foundation

// JSON parameter names
let PARAM_CODE              = "code"
let PARAM_ERROR_DETAIL      = "errorDetail"
let PARAM_TYPE              = "type"
let PARAM_VERSION           = "version"

let PARAM_ENROLL_CHALLENGES = "enrollChallenges"
let PARAM_ENROLL_DATA       = "enrollData"
let PARAM_RESPONSE_DATA     = "responseData"
let PARAM_SIGN_DATA         = "signData"

let PARAM_APP_ID_HASH       = "appIdHash"
let PARAM_CHALLENGE_HASH    = "challengeHash"
let PARAM_KEY_HANDLE        = "keyHandle"
let PARAM_SIGNATURE_DATA    = "signatureData"

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


/// An `enroll_helper_request` in the Chrome U2F helper protocol.
class EnrollHelperRequest {
    let TYPE = "enroll_helper_request"
    
    let enrollChallenges: [EnrollChallenge]
    let signChallenges: [SignChallenge]
    
    init(json: [String: Any?]) throws {
        guard try JSONUtils.string(json, PARAM_TYPE) == TYPE else {
            throw U2FError.incorrectType
        }
        
        enrollChallenges = try JSONUtils.array(json, PARAM_ENROLL_CHALLENGES).map {
            try EnrollChallenge($0)
        }
        signChallenges = try JSONUtils.array(json, PARAM_SIGN_DATA).map {
            try SignChallenge($0)
        }
    }
}

/// An `enroll_helper_reply` in the Chrome U2F helper protocol.
class EnrollHelperReply {
    let TYPE = "enroll_helper_reply"
    
    let status: DeviceStatusCode
    let version: String
    let data: Data
    
    init(status: DeviceStatusCode, version: String, data: Data) {
        self.status = status
        self.version = version
        self.data = data
    }
    
    func dump() -> [String: Any?] {
        return [
            PARAM_TYPE:         TYPE as String,
            PARAM_CODE:         status.rawValue,
            PARAM_VERSION:      version,
            PARAM_ENROLL_DATA:  WebSafeBase64.encode(data),
        ]
    }
}

/// A `sign_helper_request` in the Chrome U2F helper protocol.
class SignHelperRequest {
    let TYPE = "sign_helper_request"
    
    let signChallenges: [SignChallenge]
    
    init(json: [String: Any?]) throws {
        guard try JSONUtils.string(json, PARAM_TYPE) == TYPE else {
            throw U2FError.incorrectType
        }
        
        signChallenges = try JSONUtils.array(json, PARAM_SIGN_DATA).map {
            try SignChallenge($0)
        }
    }
}

/// A `sign_helper_reply` in the Chrome U2F helper protocol.
class SignHelperReply {
    let TYPE = "sign_helper_reply"
    
    let status: DeviceStatusCode
    let error: String?
    let signChallenge: SignChallenge?
    let data: Data?
    
    init(signChallenge: SignChallenge, data: Data) {
        self.status = .OK
        self.error = nil
        self.signChallenge = signChallenge
        self.data = data
    }
    
    init(status: DeviceStatusCode, error: String) {
        self.status = status
        self.error = error
        self.signChallenge = nil
        self.data = nil
    }
    
    func dump() -> [String: Any?] {
        var json: [String: Any?] = [
            PARAM_TYPE:             TYPE,
            PARAM_CODE:             status.rawValue,
            PARAM_ERROR_DETAIL:     error,
            PARAM_RESPONSE_DATA:    nil,
        ]
        
        if data != nil {
            json[PARAM_RESPONSE_DATA] = [
                PARAM_VERSION:          signChallenge!.version,
                PARAM_APP_ID_HASH:      WebSafeBase64.encode(signChallenge!.applicationParameter),
                PARAM_CHALLENGE_HASH:   WebSafeBase64.encode(signChallenge!.challengeParameter),
                PARAM_KEY_HANDLE:       WebSafeBase64.encode(signChallenge!.keyHandle),
                PARAM_SIGNATURE_DATA:   WebSafeBase64.encode(data!),
            ]
        }
        return json
    }
}

/// An `enrollChallenge` in the Chrome U2F helper protocol.
class EnrollChallenge {
    let version: String
    let challengeParameter: Data
    let applicationParameter: Data
    
    init(_ json: [String: Any?]) throws {
        version = try JSONUtils.string(json, PARAM_VERSION)
        challengeParameter = try JSONUtils.webSafeBase64(json, PARAM_CHALLENGE_HASH)
        applicationParameter = try JSONUtils.webSafeBase64(json, PARAM_APP_ID_HASH)
    }
}

/// A `signChallenge` in the Chrome U2F helper protocol.
class SignChallenge {
    let version: String
    let challengeParameter: Data
    let applicationParameter: Data
    let keyHandle: Data
    
    init(_ json: [String: Any?]) throws {
        version = try JSONUtils.string(json, PARAM_VERSION)
        challengeParameter = try JSONUtils.webSafeBase64(json, PARAM_CHALLENGE_HASH)
        applicationParameter = try JSONUtils.webSafeBase64(json, PARAM_APP_ID_HASH)
        keyHandle = try JSONUtils.webSafeBase64(json, PARAM_KEY_HANDLE)
    }
}

