//
//  ChromeNativeMessaging.swift
//  U2FTouchID
//
//  Created by btidor on 7/9/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation

/// Helpers for acting as a native application in Chrome's Native Messaging protocol
class ChromeNativeMessaging {
    static var MAX_INPUT: UInt32 = 1024 * 1024 // 1 MB
    
    class func receiveMessage() throws -> [String: Any] {
        let len = readInt()
        if len > MAX_INPUT { throw ChromeNativeMessagingError.inputTooLarge }
        let rawMessage = readData(ofLength: Int(len))
        let json = try JSONSerialization.jsonObject(with: rawMessage) as! [String: Any]
        return json
    }
    
    class func sendMessage(_ message: [String: Any?]) throws {
        let rawMessage = try JSONSerialization.data(withJSONObject: message)
        var len = UInt32(rawMessage.count)
        let rawLen = Data(bytes: &len, count: MemoryLayout<UInt32>.size)
        
        write(rawLen)
        write(rawMessage)
    }
    
    class func printError(_ message: Any) {
        FileHandle.standardError.write("\(message)\n".data(using: .utf8)!)
    }
    
    internal class func readInt() -> UInt32 {
        let data = FileHandle.standardInput.readData(ofLength: MemoryLayout<UInt32>.size)
        return data.withUnsafeBytes { $0.pointee } as UInt32
    }
    
    internal class func readData(ofLength: Int) -> Data {
        return FileHandle.standardInput.readData(ofLength: ofLength)
    }
    
    internal class func write(_ data: Data) {
        return FileHandle.standardOutput.write(data)
    }
    
    enum ChromeNativeMessagingError: Error {
        case inputTooLarge
    }
}
