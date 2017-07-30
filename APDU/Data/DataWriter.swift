//
//  DataWriter.swift
//  SoftU2FTool
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2017 GitHub. All rights reserved.
//

import Foundation

public protocol DataWriterProtocol {
    var buffer: Data { get }

    func write<T: EndianProtocol>(_ val: T, endian: Endian) throws
    func writeData(_ d: Data) throws
}

public class DataWriter: DataWriterProtocol {
    public var buffer = Data()

    public func write<T: EndianProtocol>(_ val: T, endian: Endian = .Big) {
        var eval: T

        switch endian {
        case .Big:
            eval = val.bigEndian
        case .Little:
            eval = val.littleEndian
        }

        buffer.append(UnsafeBufferPointer(start: &eval, count: 1))
    }

    public func write<T: EndianEnumProtocol>(_ val: T, endian: Endian = .Big) {
        write(val.rawValue)
    }

    public func writeData(_ d: Data) {
        buffer.append(d)
    }
}

