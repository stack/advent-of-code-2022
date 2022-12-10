//
//  Computer.swift
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
