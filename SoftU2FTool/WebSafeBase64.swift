//
//  WebSafeBase64.swift
//  U2FTouchID
//

import Foundation

/// Helpers for working with web-safe base 64-encoded data. See RFC 4648.
class WebSafeBase64 {
    static func encode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decode(_ string: String) -> Data? {
        var b64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding: Int

        switch b64.characters.count % 4 {
        case 0:
            padding = 0
        case 2:
            padding = 2
        case 3:
            padding = 1
        default:
            return nil
        }

        b64 += String(repeating: "=", count: padding)

        return Data(base64Encoded: b64)
    }
}
