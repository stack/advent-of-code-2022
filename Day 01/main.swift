//
//  main.swift
//  Day 01
//
//  Created by Stephen Gerstacker on 2022-12-01.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

let inputData = InputData

// MARK: - Part 1

struct Elf: CustomStringConvertible {
    var index: Int
    var calories: [Int] = []
    
    var totalCalories: Int {
        calories.reduce(0, +)
    }
    
    var description: String {
        "Elf \(index): \(totalCalories)"
    }
}

var currentElf = Elf(index: 1)
var allElves: [Elf] = []

let lines = inputData.split(separator: "\n", omittingEmptySubsequences: false)

for line in lines {
    guard !line.isEmpty  else {
        allElves.append(currentElf)
        currentElf = Elf(index: currentElf.index + 1)
        
        continue
    }
    
    guard let amount = Int(line) else {
        fatalError("Calorie line \"\(line)\" could not be parsed")
    }
                   
    currentElf.calories.append(amount)
}

if !currentElf.calories.isEmpty {
    allElves.append(currentElf)
}

let maxElf = allElves.max { $0.totalCalories < $1.totalCalories }!
print ("Max Elf: \(maxElf)")

// MARK: - Part 2

let sortedElves = allElves.sorted { $0.totalCalories > $1.totalCalories }
let top3Elves = sortedElves[0 ..< 3]

print("Top 3 Elves: \(top3Elves)")

let top3Total = top3Elves.reduce(0) { $0 + $1.totalCalories }
print("Top 3 Total: \(top3Total)")
