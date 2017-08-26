//
//  ChromeNativeMessaging.swift
//  U2FTouchID
//

import Foundation

/// Helpers for acting as a native application in Chrome's Native Messaging
/// protocol.
class ChromeNativeMessaging {
    
    /// Maximum input size. Set to 1 MB to avoid excessive resource usage.
    static var MAX_INPUT: UInt32 = 1024 * 1024
    
    /**
     Reads a length-prefixed JSON message from `stdin`.
    
     - Returns: The message as a parsed JSON object.
    */
    class func receiveMessage() throws -> [String: Any] {
        let len = readInt()
        if len > MAX_INPUT { throw ChromeNativeMessagingError.inputTooLarge }
        let rawMessage = readData(ofLength: Int(len))
        let json = try JSONSerialization.jsonObject(with: rawMessage) as! [String: Any]
        return json
    }
    
    /**
     Writes a length-prefixed JSON message to `stdout`.
 
     - Parameter message: The object to write.
    */
    class func sendMessage(_ message: [String: Any?]) throws {
        let rawMessage = try JSONSerialization.data(withJSONObject: message)
        var len = UInt32(rawMessage.count)
        let rawLen = Data(bytes: &len, count: MemoryLayout<UInt32>.size)
        
        write(rawLen)
        write(rawMessage)
    }
    
    /**
     Formats and prints an unstructured message to `stderr`. Messages will be
     transferred to Chrome's command-line output.
 
     - Parameter message: The message to print.
    */
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
