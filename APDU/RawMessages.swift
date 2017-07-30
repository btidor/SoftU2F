//
//  RawMessages.swift
//  U2FTouchID
//
//  Created by btidor on 7/30/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation

class RawMessages {
    class func enrollResponse(publicKey: Data, keyHandle: Data, certificate: Data, signature: Data) -> Data {
        var data = Data()
        data.append(UInt8(0x05)) // reserved
        data.append(publicKey)
        data.append(UInt8(keyHandle.count))
        data.append(keyHandle)
        data.append(certificate)
        data.append(signature)
        return data
    }
    
    class func enrollSignData(applicationParameter: Data, challengeParameter: Data, keyHandle: Data, publicKey: Data) -> Data {
        var data = Data()
        data.append(UInt8(0x00)) // reserved
        data.append(applicationParameter)
        data.append(challengeParameter)
        data.append(keyHandle)
        data.append(publicKey)
        return data
    }
    
    class func signResponse(userPresence: Bool, counter: UInt32, signature: Data) -> Data {
        var data = Data()
        var counterBigEndian = counter.bigEndian
        data.append(UInt8(userPresence ? 0x01 : 0x00))
        data.append(Data(bytes: &counterBigEndian, count: MemoryLayout<UInt32>.size))
        data.append(signature)
        return data
    }
    
    class func signSignData(applicationParameter: Data, userPresence: Bool, counter: UInt32, challengeParameter: Data) -> Data {
        var data = Data()
        var counterBigEndian = counter.bigEndian
        data.append(applicationParameter)
        data.append(UInt8(userPresence ? 0x01 : 0x00))
        data.append(Data(bytes: &counterBigEndian, count: MemoryLayout<UInt32>.size))
        data.append(challengeParameter)
        return data
    }
}
