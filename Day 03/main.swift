//
//  main.swift
//  Day 03
//
//  Created by Stephen H. Gerstacker on 2022-12-03.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation

let inputData = InputData
let lines = inputData.components(separatedBy: "\n")

// MARK: - Part 1

struct Rucksack {
    
    let leftCompartment: [String.Element]
    let rightCompartment: [String.Element]
    
    init(inventory: String) {
        let characters = Array(inventory)
        leftCompartment = Array(characters[0..<characters.count / 2])
        rightCompartment = Array(characters[characters.count/2 ..< characters.count])
    }
    
    var intersection: Set<String.Element> {
        let leftSet = Set(leftCompartment)
        let rightSet = Set(rightCompartment)
        
        return leftSet.intersection(rightSet)
    }
    
    var priorities: [Int] {
        intersection.map {
            let value = $0.asciiValue!
            
            if value >= 65 && value <= 90 {
                return Int(value - 64) + 26
            } else if value >= 97 && value <= 122 {
                return Int(value - 96)
            } else {
                fatalError("Unhandled ascii value: \(value)")
            }
        }
    }
    
    var leftString: String {
        leftCompartment.map { String($0) }.joined()
    }
    
    var rightString: String {
        rightCompartment.map { String($0) }.joined()
    }
}

let rucksacks = lines.map { Rucksack(inventory: $0) }

print("Part 1:")

var total = 0

for rucksack in rucksacks {
    print("\(rucksack.leftString) || \(rucksack.rightString) -> \(rucksack.intersection) -> \(rucksack.priorities)")
    
    let sum = rucksack.priorities.reduce(0, +)
    total += sum
}

print("Total: \(total)")

// MARK: - Part 2

struct Group {
    let rucksacks: [String]
    
    var intersection: Set<String.Element> {
        var remaining = rucksacks
        var result = Set(remaining.removeFirst())
        
        while !remaining.isEmpty {
            let current = Set(remaining.removeFirst())
            result = result.intersection(current)
        }
        
        return result
    }
    
    var priorities: [Int] {
        intersection.map {
            let value = $0.asciiValue!
            
            if value >= 65 && value <= 90 {
                return Int(value - 64) + 26
            } else if value >= 97 && value <= 122 {
                return Int(value - 96)
            } else {
                fatalError("Unhandled ascii value: \(value)")
            }
        }
    }
}

let groups = lines.chunks(ofCount: 3).map {
    Group(rucksacks: Array($0))
}

print()
print("Part 2:")

total = 0

for group in groups {
    print("\(group.intersection) -> \(group.priorities)")
    
    let sum = group.priorities.reduce(0, +)
    total += sum
}

print("Total: \(total)")
