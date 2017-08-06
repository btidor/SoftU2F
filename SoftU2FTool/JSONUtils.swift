//
//  JSONUtils.swift
//  SoftU2FTool
//

import Foundation

/// Helpers for parsing JSON objects. 
class JSONUtils {
    static func string(_ json: [String: Any?], _ key: String) throws -> String {
        guard let value = json[key] else {
            throw SerializationError.missing(key, from: json)
        }
        guard let typedValue = value as? String else {
            throw SerializationError.invalid(key, value)
        }
        return typedValue
    }
    
    static func int(_ json: [String: Any?], _ key: String) throws -> Int {
        guard let value = json[key] else {
            throw SerializationError.missing(key, from: json)
        }
        guard let typedValue = value as? Int else {
            throw SerializationError.invalid(key, value)
        }
        return typedValue
    }
    
    static func webSafeBase64(_ json: [String: Any?], _ key: String) throws -> Data {
        let stringValue = try string(json, key)
        guard let decodedValue = WebSafeBase64.decode(stringValue) else {
            throw SerializationError.invalid(key, stringValue)
        }
        return decodedValue
    }
    
    static func array(_ json: [String: Any?], _ key: String) throws -> [[String: Any?]] {
        guard let value = json[key] else {
            throw SerializationError.missing(key, from: json)
        }
        guard let typedValue = value as? [[String: Any]] else {
            throw SerializationError.invalid(key, value)
        }
        return typedValue
    }
    
    enum SerializationError: Error {
        case missing(String, from: Any?)
        case invalid(String, Any?)
    }
}
