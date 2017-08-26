//
//  RawMessages.swift
//  U2FTouchID
//

import Foundation

/// Helpers for constructing the packed binary messages used in the U2F
/// protocol. See "FIDO U2F Raw Message Formats", 11 April 2017.
class RawMessages {
    
    /// 4.3 - Registration Response Message: Success
    static func registrationResponse(publicKey: Data, keyHandle: Data, certificate: Data, signature: Data) -> Data {
        var data = Data()
        data.append(UInt8(0x05)) // reserved
        data.append(publicKey)
        data.append(UInt8(keyHandle.count))
        data.append(keyHandle)
        data.append(certificate)
        data.append(signature)
        return data
    }
    
    /// 4.3 - data under signature in Registration Response Message: Success
    static func registrationDataToSign(applicationParameter: Data, challengeParameter: Data, keyHandle: Data, publicKey: Data) -> Data {
        var data = Data()
        data.append(UInt8(0x00)) // reserved
        data.append(applicationParameter)
        data.append(challengeParameter)
        data.append(keyHandle)
        data.append(publicKey)
        return data
    }
    
    /// 5.4 - Authentication Response Message: Success
    static func authenticationResponse(userPresence: Bool, counter: UInt32, signature: Data) -> Data {
        var data = Data()
        var counterBigEndian = counter.bigEndian
        data.append(UInt8(userPresence ? 0x01 : 0x00))
        data.append(Data(bytes: &counterBigEndian, count: MemoryLayout<UInt32>.size))
        data.append(signature)
        return data
    }
    
    /// 5.4 - data under signature in Authentication Response Message: Success
    static func authenticationDataToSign(applicationParameter: Data, userPresence: Bool, counter: UInt32, challengeParameter: Data) -> Data {
        var data = Data()
        var counterBigEndian = counter.bigEndian
        data.append(applicationParameter)
        data.append(UInt8(userPresence ? 0x01 : 0x00))
        data.append(Data(bytes: &counterBigEndian, count: MemoryLayout<UInt32>.size))
        data.append(challengeParameter)
        return data
    }
}
