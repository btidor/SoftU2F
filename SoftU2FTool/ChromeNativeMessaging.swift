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
    static func receiveMessage() throws -> [String: Any] {
        let len = readInt()
        let rawMessage = FileHandle.standardInput.readData(ofLength: Int(len))
        let json = try JSONSerialization.jsonObject(with: rawMessage) as! [String: Any]
        return json
    }
    
    static func sendMessage(_ message: [String: Any]) throws {
        let rawMessage = try JSONSerialization.data(withJSONObject: message)
        var len = UInt32(rawMessage.count)
        let rawLen = Data(bytes: &len, count: MemoryLayout<UInt32>.size)
        
        FileHandle.standardOutput.write(rawLen)
        FileHandle.standardOutput.write(rawMessage)
    }
    
    static func printEror(_ message: Any) {
        FileHandle.standardError.write("\(message)\n".data(using: .utf8)!)
    }
    
    private static func readInt() -> UInt32 {
        let data = FileHandle.standardInput.readData(ofLength: MemoryLayout<UInt32>.size)
        return data.withUnsafeBytes { $0.pointee } as UInt32
    }
}
