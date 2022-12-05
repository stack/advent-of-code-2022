//
//  main.swift
//  Day 05
//
//  Created by Stephen Gerstacker on 2022-12-05.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

let inputData = InputData

// MARK: - Part 1

print("### Part 1 ###")
print()

let shipyard1 = Shipyard(mode: .model9000)

for line in inputData.components(separatedBy: "\n") {
    shipyard1.parseLine(line)
}

print()
print("Message: \(shipyard1.message)")

// MARK: - Part 2

print()
print("### Part 2 ###")
print()

let shipyard2 = Shipyard(mode: .model9001)

for line in inputData.components(separatedBy: "\n") {
    shipyard2.parseLine(line)
}

print()
print("Message: \(shipyard2.message)")
