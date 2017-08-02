//
//  SoftU2FTestCase.swift
//  SoftU2FTool
//
//  Created by Benjamin P Toews on 1/30/17.
//  Copyright © 2017 GitHub. All rights reserved.
//

import XCTest
@testable import SoftU2FTool

class SoftU2FTestCase: XCTestCase {
    static var nameSpaceWas = Token.namespace

    override static func setUp() {
        // Use separate namespace for keychain entries.
        Token.namespace = "SoftU2F Tests"

        // Clear any lingering keychain entries.
        let _ = Token.deleteAll()

        super.setUp()
    }

    override static func tearDown() {
        Token.namespace = nameSpaceWas
    }
}
