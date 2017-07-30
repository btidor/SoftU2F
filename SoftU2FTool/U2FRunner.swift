//
//  U2FRunner.swift
//  U2FTouchID
//
//  Created by btidor on 7/29/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation

import SelfSignedCertificate

class U2FRunner {
    class func run() {
        do {
            let message = try ChromeNativeMessaging.receiveMessage()
            let reply : [String : Any?]
            
            let type = try JSONUtils.string(message, "type")
            switch type {
            case "enroll_helper_request":
                reply = try processEnrollRequest(json: message)
            case "sign_helper_request":
                reply = try processSignRequest(json: message)
            default:
                throw U2FError.unknownRequestType(type)
            }
            
            try ChromeNativeMessaging.sendMessage(reply)
        } catch let err {
            ChromeNativeMessaging.printError("Error: \(err)")
            exit(1)
        }
    }
    
    class func processEnrollRequest(json: [String: Any]) throws -> [String: Any?] {
        let request = try EnrollHelperRequest.init(json: json)
        for challenge in request.enrollChallenges {
            if challenge.version == U2F_VERSION {
                return try doEnroll(challenge)
            }
        }
        throw U2FError.noSupportedChallenge
    }
    
    class func doEnroll(_ challenge: EnrollChallenge) throws -> [String: Any?] {
        guard let reg = Token(applicationParameter: challenge.applicationParameter) else {
            throw U2FError.nullError
        }
        
        guard let publicKey = reg.keyPair.publicKeyData else {
            throw U2FError.nullError
        }
        
        let sigPayload = RawMessages.enrollSignData(applicationParameter: challenge.applicationParameter, challengeParameter: challenge.challengeParameter, keyHandle: reg.keyHandle, publicKey: publicKey)
        
        guard let sig = SelfSignedCertificate.sign(sigPayload) else {
            throw U2FError.nullError
        }
        
        
        let resp = RawMessages.enrollResponse(publicKey: publicKey, keyHandle: reg.keyHandle, certificate: SelfSignedCertificate.toDer(), signature: sig)
        
        let reply = EnrollHelperReply(code: DeviceStatusCode.OK, version: U2F_VERSION, data: resp)
        return reply.dump()
    }
    
    class func processSignRequest(json: [String: Any]) throws -> [String: Any?] {
        let request = try SignHelperRequest.init(json: json)
        for challenge in request.signChallenges {
            if challenge.version == U2F_VERSION {
                let reg = Token(keyHandle: challenge.keyHandle, applicationParameter: challenge.applicationParameter)
                if reg != nil {
                    return try doSign(challenge: challenge, with: reg!)
                }
            }
        }
        throw U2FError.noSupportedChallenge
    }
    
    class func doSign(challenge: SignChallenge, with token: Token) throws -> [String: Any?] {
        let counter = token.counter
        
        let sigPayload = RawMessages.signSignData(applicationParameter: challenge.applicationParameter, userPresence: true, counter: counter, challengeParameter: challenge.challengeParameter)
        
        guard let sig = token.sign(sigPayload) else {
            throw U2FError.nullError
        }
        
        let resp = RawMessages.signResponse(userPresence: true, counter: counter, signature: sig)
        
        let reply = SignHelperReply.init(signChallenge: challenge, data: resp)
        return reply.dump()
    }
    
}
