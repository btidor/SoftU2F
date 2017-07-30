//
//  DataWriterTests.swift
//  SoftU2FTool
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2017 GitHub. All rights reserved.
//

import XCTest

class DataWriterTests: XCTestCase {
    func testWrite() throws {
        let writer = DataWriter()
        writer.write(UInt8(0x00))
        writer.write(UInt8(0xFF), endian: .Little)
        writer.write(UInt16(0x0102))
        writer.write(UInt16(0x0102), endian: .Little)
        writer.writeData("AB".data(using: .utf8)!)

        XCTAssertEqual(Data(bytes: [0x00, 0xFF, 0x01, 0x02, 0x02, 0x01, 0x41, 0x42]), writer.buffer)
    }
}
