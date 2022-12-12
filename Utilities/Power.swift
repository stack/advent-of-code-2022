//
//  Power.swift
//  Utilities
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  SPDX-License-Identifier: MIT
//

import Foundation

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence

public func ^^(radis: Int, power: Int) -> Int {
    return Int(pow(Double(radis), Double(power)))
}
