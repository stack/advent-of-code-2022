//
//  Power.swift
//  Utilities
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence

public func ^^(radis: Int, power: Int) -> Int {
    return Int(pow(Double(radis), Double(power)))
}
