//
//  Math.swift
//  Utilities
//
//  Created by Stephen Gerstacker on 2022-12-22.
//  SPDX-License-Identifier: MIT
//

import Foundation

public func gcd<T: SignedInteger>(_ a: T, _ b: T) -> T {
    let r = a % b
    
    if r != 0 {
        return gcd(b, r)
    } else {
        return b
    }
}
