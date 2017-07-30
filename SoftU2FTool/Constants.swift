//
//  Constants.swift
//  U2FTouchID
//
//  Created by btidor on 7/30/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

let U2F_VERSION = "U2F_V2"

enum U2FError: Error {
    case unknownRequestType(String)
    case noSupportedChallenge
    case nullError // TODO: convert return-null functions to throw errors
}
