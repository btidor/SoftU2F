//
//  Constants.swift
//  U2FTouchID
//

let U2F_VERSION = "U2F_V2"

enum U2FError: Error {
    case unknownRequestType(String)
    case noSupportedChallenge
    case keychainError(String, Int?, String?)
    case keyNotFound
    case nilError // TODO: convert return-nil functions to throw errors
    case unsupportedOSVersion
    case incorrectType
    case userCanceled
}
