//
//  RegisterResponse.swift
//  SoftU2FTool
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2017 GitHub. All rights reserved.
//

import Foundation
import SelfSignedCertificate

let U2F_EC_KEY_SIZE = 32                            // EC key size in bytes
let U2F_EC_POINT_SIZE = ((U2F_EC_KEY_SIZE * 2) + 1) // Size of EC point

public struct RegisterResponse {
    public let body: Data

    var reserved: UInt8 {
        return body.subdata(in: reservedRange)[0]
    }
    
    public var publicKey: Data {
        return body.subdata(in: publicKeyRange)
    }
    
    var keyHandleLength: Int {
        return Int(body.subdata(in: keyHandleLengthRange)[0])
    }

    public var keyHandle: Data {
        return body.subdata(in: keyHandleRange)
    }
    
    public var certificate: Data {
        return body.subdata(in: certificateRange)
    }

    public var signature: Data {
        return body.subdata(in: signatureRange)
    }

    var reservedRange: Range<Int> {
        let lowerBound = 0
        let upperBound = MemoryLayout<UInt8>.size
        return lowerBound..<upperBound
    }
    
    var publicKeyRange: Range<Int> {
        let lowerBound = reservedRange.upperBound
        let upperBound = lowerBound + U2F_EC_POINT_SIZE
        return lowerBound..<upperBound
    }
    
    var keyHandleLengthRange: Range<Int> {
        let lowerBound = publicKeyRange.upperBound
        let upperBound = lowerBound + MemoryLayout<UInt8>.size
        return lowerBound..<upperBound
    }

    var keyHandleRange: Range<Int> {
        let lowerBound = keyHandleLengthRange.upperBound
        let upperBound = lowerBound + keyHandleLength
        return lowerBound..<upperBound
    }
    
    var certificateSize: Int {
        let remainingRange: Range<Int> = keyHandleRange.upperBound..<body.count
        let remaining = body.subdata(in: remainingRange)
        var size: Int = 0

        if SelfSignedCertificate.parseX509(remaining, consumed: &size) {
            return size
        } else {
            return 0
        }
    }
    
    var certificateRange: Range<Int> {
        let lowerBound = keyHandleRange.upperBound
        let upperBound = lowerBound + certificateSize
        return lowerBound..<upperBound
    }
    
    var signatureRange: Range<Int> {
        let lowerBound = certificateRange.upperBound
        let upperBound = body.count
        return lowerBound..<upperBound
    }
    
    public init(publicKey: Data, keyHandle: Data, certificate: Data, signature: Data) {
        let writer = DataWriter()
        writer.write(UInt8(0x05)) // reserved
        writer.writeData(publicKey)
        writer.write(UInt8(keyHandle.count))
        writer.writeData(keyHandle)
        writer.writeData(certificate)
        writer.writeData(signature)

        body = writer.buffer
    }
}
