//
//  U2FRunner.swift
//  U2FTouchID
//
//  Created by btidor on 7/29/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation

import APDU
import SelfSignedCertificate

class U2FRunner {
    class func run() {
        do {
            let request = try ChromeNativeMessaging.receiveMessage()
            let reply : [String : Any?]
            
            let type = try JSONUtils.string(request, "type")
            switch type {
            case "enroll_helper_request":
                reply = try processEnrollRequest(json: request)
            case "sign_helper_request":
                reply = try processSignRequest(json: request)
            default:
                throw U2FRunnerError.unknownRequestType(type)
            }
            
            try ChromeNativeMessaging.sendMessage(reply)
            exit(0)
        } catch let err {
            ChromeNativeMessaging.printError("Error: \(err)")
            exit(1)
        }
    }
    
    class func processEnrollRequest(json: [String: Any]) throws -> [String: Any?] {
        let request = try EnrollHelperRequest.init(json: json)
        
        // TODO: de-duplicate keys using signChallenges? check spec
        var challenge : EnrollChallenge?
        for c in request.enrollChallenges {
            if c.version == "U2F_V2" {
                challenge = c
                break
            }
        }
        guard challenge != nil else {
            throw U2FRunnerError.noSupportedChallenge
        }
        
        guard let reg = U2FRegistration(applicationParameter: challenge!.applicationParameter) else {
            throw U2FRunnerError.nullError
        }
        
        guard let publicKey = reg.keyPair.publicKeyData else {
            throw U2FRunnerError.nullError
        }
        
        let payloadSize = 1 + challenge!.applicationParameter.count + challenge!.challengeParameter.count + reg.keyHandle.count + publicKey.count
        var sigPayload = Data(capacity: payloadSize)
        
        sigPayload.append(UInt8(0x00)) // reserved
        sigPayload.append(challenge!.applicationParameter)
        sigPayload.append(challenge!.challengeParameter)
        sigPayload.append(reg.keyHandle)
        sigPayload.append(publicKey)
        
        guard let sig = SelfSignedCertificate.sign(sigPayload) else {
            throw U2FRunnerError.nullError
        }
        
        let resp = RegisterResponse(publicKey: publicKey, keyHandle: reg.keyHandle, certificate: SelfSignedCertificate.toDer(), signature: sig)
        
        let reply = EnrollHelperReply(code: DeviceStatusCode.OK, version: "U2F_V2", data: resp.raw)
        return reply.dump()
    }
    
    class func processSignRequest(json: [String: Any]) throws -> [String: Any?] {
        let request = try SignHelperRequest.init(json: json)
        
        var challenge : SignChallenge?
        var reg : U2FRegistration?
        for c in request.signChallenges {
            if c.version == "U2F_V2" {
                challenge = c
                reg = U2FRegistration(keyHandle: c.keyHandle, applicationParameter: c.applicationParameter)
                guard reg != nil else {
                    continue
                }
                break
            }
        }
        guard reg != nil else {
            throw U2FRunnerError.noSupportedChallenge
        }
     
        let counter = reg!.counter
        var ctrBigEndian = counter.bigEndian
        
        let payloadSize = challenge!.applicationParameter.count + 1 + MemoryLayout<UInt32>.size + challenge!.challengeParameter.count
        var sigPayload = Data(capacity: payloadSize)
        
        sigPayload.append(challenge!.applicationParameter)
        sigPayload.append(UInt8(0x01)) // user present
        sigPayload.append(Data(bytes: &ctrBigEndian, count: MemoryLayout<UInt32>.size))
        sigPayload.append(challenge!.challengeParameter)
        
        guard let sig = reg!.sign(sigPayload) else {
            throw U2FRunnerError.nullError
        }
        
        let resp = AuthenticationResponse(userPresence: 0x01, counter: counter, signature: sig)
        
        let reply = SignHelperReply.init(signChallenge: challenge!, data: resp.raw)
        return reply.dump()
    }
    
    enum U2FRunnerError: Error {
        case unknownRequestType(String)
        case noSupportedChallenge // TODO: convert to protocol error?
        case nullError // TODO: convert return-null functions to throw errors
    }
}
