//
//  Utils.swift
//  U2FTouchID
//

import Foundation

let FifyZeros = Data(repeating: 0x00, count: 50)

// Conformance test fails if key handle is less than 64 bytes...
func padKeyHandle(_ kh: Data) -> Data {
    var new = kh
    new.append(FifyZeros)
    return new
}

// Conformance test fails if key handle is less than 64 bytes...
func unpadKeyHandle(_ kh: Data) -> Data {
    let padIdx = kh.count - FifyZeros.count

    if padIdx <= 0 {
        return kh
    }

    return kh.subdata(in: 0..<padIdx)
}
