//
//  main.swift
//  Day 25
//
//  Created by Stephen H. Gerstacker on 2022-12-25.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Utilities

func dec2Snafu(_ dec: Int) -> String {
    var parts: [String] = []
    var value = dec
    
    while value > 0 {
        let rem = value % 5
        value = value / 5
        
        
        switch rem {
        case 0, 1, 2:
            parts.append(String(rem))
        case 3:
            value += 1
            parts.append("=")
        case 4:
            value += 1
            parts.append("-")
        default:
            fatalError("Invalid remainder: \(rem)")
        }
    }
    
    return parts.reversed().joined()
}

func snafu2Dec(_ snafu: String) -> Int {
    let parts = snafu.map {
        switch $0 {
        case "2": return 2
        case "1": return 1
        case "0": return 0
        case "-": return -1
        case "=": return -2
        default:
            fatalError("Unsupported character: \($0)")
        }
    }
    
    let total = parts.reversed().enumerated().reduce(0) { (sum, item) in
        let factor = 5 ^^ item.offset
        let value = item.element * factor
        
        return sum + value
    }
    
    return total
}

assert(snafu2Dec("1=-0-2") == 1747)
assert(snafu2Dec("12111") == 906)
assert(snafu2Dec("2=0=") == 198)
assert(snafu2Dec("21") == 11)
assert(snafu2Dec("2=01") == 201)
assert(snafu2Dec("111") == 31)
assert(snafu2Dec("20012") == 1257)
assert(snafu2Dec("112") == 32)
assert(snafu2Dec("1=-1=") == 353)
assert(snafu2Dec("1-12") == 107)
assert(snafu2Dec("12") == 7)
assert(snafu2Dec("1=") == 3)
assert(snafu2Dec("122") == 37)

assert(dec2Snafu(1747) == "1=-0-2")
assert(dec2Snafu(906) == "12111")
assert(dec2Snafu(198) == "2=0=")
assert(dec2Snafu(11) == "21")
assert(dec2Snafu(201) == "2=01")
assert(dec2Snafu(31) == "111")
assert(dec2Snafu(1257) == "20012")
assert(dec2Snafu(32) == "112")
assert(dec2Snafu(353) == "1=-1=")
assert(dec2Snafu(107) == "1-12")
assert(dec2Snafu(7) == "12")
assert(dec2Snafu(3) == "1=")
assert(dec2Snafu(37) == "122")

func part1(data: String) -> String {
    let sum = data.components(separatedBy: "\n").reduce(0) { $0 + snafu2Dec($1) }
    let snafu = dec2Snafu(sum)
    
    return snafu
}

print("== Part 1 ==")

let sample1Sum = part1(data: SampleData)
print("Sample Sum: \(sample1Sum)")

let input1Sum = part1(data: InputData)
print("Input Sum: \(input1Sum)")
