//
//  U2FRunner.swift
//  U2FTouchID
//

import Foundation

import SelfSignedCertificate

class U2FRunner {
    static func run() {
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
    
    static func processEnrollRequest(json: [String: Any]) throws -> [String: Any?] {
        let request = try EnrollHelperRequest.init(json: json)
        for challenge in request.enrollChallenges {
            if challenge.version == U2F_VERSION {
                return try doEnroll(challenge)
            }
        }
        throw U2FError.noSupportedChallenge
    }
    
    static func doEnroll(_ challenge: EnrollChallenge) throws -> [String: Any?] {
        let metadata = try U2FRunner.generateMetadata(counter: 0, applicationParameter: challenge.applicationParameter)
        let privateKey = try Keychain.generatePrivateKey(metadata: metadata)
        let publicKey = try Keychain.exportPublicKey(from: privateKey)
        let keyFingerprint = try Keychain.getKeyFingerprint(privateKey: privateKey)
        let keyHandle = padKeyHandle(keyFingerprint)
        
        let sigPayload = RawMessages.registrationDataToSign(applicationParameter: challenge.applicationParameter, challengeParameter: challenge.challengeParameter, keyHandle: keyHandle, publicKey: publicKey)
        guard let sig = SelfSignedCertificate.sign(sigPayload) else {
            throw U2FError.internalError("SelfSignedCertificate failed to create signature")
        }
        let resp = RawMessages.registrationResponse(publicKey: publicKey, keyHandle: keyHandle, certificate: SelfSignedCertificate.toDer(), signature: sig)
        let reply = EnrollHelperReply(status: .OK, version: U2F_VERSION, data: resp)
        return reply.dump()
    }
    
    static func processSignRequest(json: [String: Any]) throws -> [String: Any?] {
        let request = try SignHelperRequest.init(json: json)
        for challenge in request.signChallenges {
            if challenge.version == U2F_VERSION {
                do {
                    let keyFingerprint = unpadKeyHandle(challenge.keyHandle)
                    let privateKey = try Keychain.findPrivateKey(keyFingerprint: keyFingerprint)
                    return try doSign(challenge: challenge, privateKey: privateKey)
                } catch U2FError.keyNotFound {
                    continue
                }
            }
        }
        throw U2FError.noSupportedChallenge
    }
    
    static func doSign(challenge: SignChallenge, privateKey: SecKey) throws -> [String: Any?] {
        let keyFingerprint = unpadKeyHandle(challenge.keyHandle)
        let metadata = try Keychain.getKeyMetadata(keyFingerprint: keyFingerprint)
        let (originalCounter, originalApplicationParameter) = try U2FRunner.getCounterAndApplicationParameter(metadata: metadata)
        let newMetadata = try generateMetadata(counter: originalCounter + 1, applicationParameter: originalApplicationParameter)
        try Keychain.setKeyMetadata(keyFingerprint: keyFingerprint, metadata: newMetadata)
        
        guard challenge.applicationParameter == originalApplicationParameter else {
            throw U2FError.keyNotFound
        }
        
        let sigPayload = RawMessages.authenticationDataToSign(applicationParameter: challenge.applicationParameter, userPresence: true, counter: UInt32(originalCounter), challengeParameter: challenge.challengeParameter)

        do {
            let sig = try Keychain.sign(data: sigPayload, with: privateKey)
            let resp = RawMessages.authenticationResponse(userPresence: true, counter: originalCounter, signature: sig)
            let reply = SignHelperReply.init(signChallenge: challenge, data: resp)
            return reply.dump()
        } catch U2FError.userCanceled {
            let reply = SignHelperReply.init(status: .WAIT_TOUCH, error: "User canceled")
            return reply.dump()
        }
    }

    static func generateMetadata(counter: UInt32, applicationParameter: Data) throws -> Data {
        let object: [String: Any] = [
            "counter": counter,
            "applicationParameter": WebSafeBase64.encode(applicationParameter),
        ]
        return try JSONSerialization.data(withJSONObject: object)
    }
    
    static func getCounterAndApplicationParameter(metadata: Data) throws -> (UInt32, Data) {
        let json = try JSONSerialization.jsonObject(with: metadata) as! [String: Any?]
        let counter = try UInt32(JSONUtils.int(json, "counter"))
        let applicationParameter = try JSONUtils.webSafeBase64(json, "applicationParameter")
        return (counter, applicationParameter)
    }
}
