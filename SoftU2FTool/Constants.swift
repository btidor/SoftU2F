//
//  Constants.swift
//  U2FTouchID
//

let U2F_VERSION = "U2F_V2"

enum U2FError: Error {
    /// The request's `type` is unknown.
    case unknownRequestType(String)
    
    /// The request does not contain any challenge with a `version` supported by
    /// this application.
    case noSupportedChallenge
    
    /// An error was received when calling an OS X Keychain or Security API.
    case keychainError(String, Int?, String?)
    
    /// No key matching the given parameters was found in the Keychain.
    case keyNotFound
    
    /// The user refused permission for this security action.
    case userCanceled
    
    /// This application is running on an unsupported version of OS X.
    case unsupportedOSVersion
    
    /// An unexpected error occurred.
    case internalError(String)
}
