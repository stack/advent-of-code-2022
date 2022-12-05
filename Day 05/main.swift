//
//  main.swift
//  Day 05
//
//  Created by Stephen Gerstacker on 2022-12-05.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Algorithms
import Foundation



class Shipyard {
    
    enum CraneMode {
        case model9000
        case model9001
    }
    
    enum ParserMode {
        case crates
        case moves
    }
    
    private let movesRegex = /^move (\d+) from (\d+) to (\d+)$/
    
    private var craneMode: CraneMode
    private var parserMode: ParserMode
    private var stacks: [[Character]]
    
    var message: String {
        stacks.map { String($0.last!) }.joined()
    }
    
    init(mode: CraneMode) {
        self.craneMode = mode
        self.parserMode = .crates
        self.stacks = []
    }
    
    func parseLine(_ line: String) {
        switch parserMode {
        case .crates:
            let chunks = line.chunks(ofCount: 4)
            
            if let first = chunks.first, first.starts(with: " 1 ") {
                print("Initial State:")
                dumpStacks()
                
                parserMode = .moves
                
                return
            }
            
            for (stackIndex, chunk) in chunks.enumerated() {
                if stacks.count <= stackIndex {
                    stacks.append([])
                }
                
                let value = chunk[chunk.index(chunk.startIndex, offsetBy: 1)]
                
                if value != " " {
                    stacks[stackIndex].insert(value, at: 0)
                }
            }
        case .moves:
            guard let match = line.firstMatch(of: movesRegex) else {
                return
            }
            
            let (_, countString, sourceIndexString, targetIndexString) = match.output
            let count = Int(countString)!
            let sourceIndex = Int(sourceIndexString)! - 1
            let targetIndex = Int(targetIndexString)! - 1
            
            print()
            print("Move \(count) from \(sourceIndex) to \(targetIndex):")
            
            switch craneMode {
            case .model9000:
                for _ in 0 ..< count {
                    let value = stacks[sourceIndex].removeLast()
                    stacks[targetIndex].append(value)
                }
            case .model9001:
                let lhs = stacks[sourceIndex].count - count
                let rhs = stacks[sourceIndex].count
                let range = lhs ..< rhs
                
                let values = stacks[sourceIndex][range]
                stacks[sourceIndex].removeLast(count)
                stacks[targetIndex].append(contentsOf: values)
            }
            
            dumpStacks()
        }
    }
    
    func dumpStacks() {
        var lines: [String] = []
        let maxHeight = stacks.map { $0.count }.max()!
        
        for y in stride(from: maxHeight - 1, through: 0, by: -1) {
            var line = ""
            
            for stack in stacks {
                if y >= stack.count {
                    line += "    "
                } else {
                    line += "[" + String(stack[y]) + "] "
                }
            }
            
            lines.append(line)
        }
        
        let result = lines.joined(separator: "\n")
        
        print(result)
    }
}

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
