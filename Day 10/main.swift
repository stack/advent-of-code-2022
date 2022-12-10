//
//  main.swift
//  Day 10
//
//  Created by Stephen H. Gerstacker on 2022-12-10.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

class Computer {
    
    private(set) var cycle = 0
    private(set) var registerX = 1
    
    func run(inputData: String, onCycle: (String, Int, Int) -> Void) {
        let addXRegex = /^addx (-?\d+)$/
        let noopRegex = /^noop$/
        
        for line in inputData.components(separatedBy: "\n") {
            if let match = line.firstMatch(of: addXRegex) {
                let (_, valueString) = match.output
                let value = Int(valueString)!
                
                cycle += 1
                onCycle(line, cycle, registerX)
                
                cycle += 1
                onCycle(line, cycle, registerX)
                
                registerX += value
            } else if let _ = line.firstMatch(of: noopRegex) {
                cycle += 1
                onCycle(line, cycle, registerX)
            }
        }
    }
}

// MARK: - Part 1, Sample 1

let computerSample1 = Computer()
computerSample1.run(inputData: SampleData1) { _, cycle, registerX in
    print("[\(cycle)] X: \(registerX)")
}

// MARK: - Part 1, Sample 2

print()

let computerSample2 = Computer()

var sample2Sum = 0
computerSample2.run(inputData: SampleData2) { instruction, cycle, registerX in
    // print("         \(instruction)")
    // print("         [\(cycle)] X: \(registerX)")
    
    if (cycle - 20) % 40 == 0 {
        sample2Sum += (cycle * registerX)
        print("[\(cycle)] X: \(registerX), SS: \(cycle * registerX), T: \(sample2Sum)")
        
    }
}

print("Sample 2 Sum: \(sample2Sum)")

// MARK: - Part 1, Input

print()

let computerInput1 = Computer()

var input1Sum = 0
computerInput1.run(inputData: InputData) { _, cycle, registerX in
    if (cycle - 20) % 40 == 0 {
        input1Sum += (cycle * registerX)
        print("[\(cycle)] X: \(registerX), SS: \(cycle * registerX), T: \(input1Sum)")
        
    }
}

print("Input 1 Sum: \(input1Sum)")

// MARK: - Part 2, Sample 2

print()

let computerSample2Part2 = Computer()

var currentLine = ""
computerSample2Part2.run(inputData: SampleData2) { _, cycle, registerX in
    // let row = (cycle - 1) / 40
    let column = (cycle - 1) % 40
    
    let spritePosition = (registerX - 1) ... (registerX + 1)
    
    // print("Sprite: \(spritePosition)")
    
    if spritePosition.contains(column) {
        currentLine += "#"
    } else {
        currentLine += "."
    }
    
    // print("Row: \(currentLine)")
    
    if column == 39 {
        print(currentLine)
        currentLine = ""
    }
}

// MARK: - Part 2, Input

print()

let computerInput1Part2 = Computer()

currentLine = ""
computerInput1Part2.run(inputData: InputData) { _, cycle, registerX in
    // let row = (cycle - 1) / 40
    let column = (cycle - 1) % 40
    
    let spritePosition = (registerX - 1) ... (registerX + 1)
    
    // print("Sprite: \(spritePosition)")
    
    if spritePosition.contains(column) {
        currentLine += "#"
    } else {
        currentLine += "."
    }
    
    // print("Row: \(currentLine)")
    
    if column == 39 {
        print(currentLine)
        currentLine = ""
    }
}
