//
//  Shipyard.swift
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
    
    struct Crate: Identifiable {
        let id: String
        let value: String
    }
    
    struct LastMove {
        let crates: [Crate]
        let sourceColumn: Int
        let sourceRow: Int
        let targetColumn: Int
        let targetRow: Int
    }
    
    private let movesRegex = /^move (\d+) from (\d+) to (\d+)$/
    
    private var craneMode: CraneMode
    private(set) var parserMode: ParserMode
    private(set) var stacks: [[Crate]]
    
    private(set) var lastMoves: [LastMove] = []
    
    private let shouldDump: Bool
    
    var message: String {
        stacks.map { String($0.last!.value) }.joined()
    }
    
    init(mode: CraneMode, shouldDump: Bool = true) {
        self.craneMode = mode
        self.parserMode = .crates
        self.stacks = []
        
        self.shouldDump = shouldDump
    }
    
    func parseLine(_ line: String) {
        lastMoves.removeAll()
        
        switch parserMode {
        case .crates:
            let chunks = line.chunks(ofCount: 4)
            
            if let first = chunks.first, first.starts(with: " 1 ") {
                if shouldDump {
                    print("Initial State:")
                    dumpStacks()
                }
                
                parserMode = .moves
                
                return
            }
            
            for (stackIndex, chunk) in chunks.enumerated() {
                if stacks.count <= stackIndex {
                    stacks.append([])
                }
                
                let value = chunk[chunk.index(chunk.startIndex, offsetBy: 1)]
                
                if value != " " {
                    let id = "\(value)-\(stackIndex)-\(stacks[stackIndex].count)"
                    let crate = Crate(id: id, value: String(value))
                    stacks[stackIndex].insert(crate, at: 0)
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
            
            if shouldDump {
                print()
                print("Move \(count) from \(sourceIndex) to \(targetIndex):")
            }
            
            switch craneMode {
            case .model9000:
                for _ in 0 ..< count {
                    let value = stacks[sourceIndex].removeLast()
                    
                    let lastMove = LastMove(crates: [value], sourceColumn: sourceIndex, sourceRow: stacks[sourceIndex].count, targetColumn: targetIndex, targetRow: stacks[targetIndex].count)
                    lastMoves.append(lastMove)
                    
                    stacks[targetIndex].append(value)
                }
            case .model9001:
                let lhs = stacks[sourceIndex].count - count
                let rhs = stacks[sourceIndex].count
                let range = lhs ..< rhs
                
                let values = stacks[sourceIndex][range]
                stacks[sourceIndex].removeLast(count)
                
                let lastMove = LastMove(crates: Array(values), sourceColumn: sourceIndex, sourceRow: stacks[sourceIndex].count, targetColumn: targetIndex, targetRow: stacks[targetIndex].count)
                lastMoves.append(lastMove)
                
                stacks[targetIndex].append(contentsOf: values)
            }
            
            if shouldDump {
                dumpStacks()
            }
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
                    line += "[" + String(stack[y].value) + "] "
                }
            }
            
            lines.append(line)
        }
        
        let result = lines.joined(separator: "\n")
        
        print(result)
    }
}
