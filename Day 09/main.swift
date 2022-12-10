//
//  main.swift
//  Day 09
//
//  Created by Stephen H. Gerstacker on 2022-12-09.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import Utilities
import simd

class Bridge {
    
    private(set) var headPosition: Point = .zero
    private(set) var tailPositions: [Point]

    private(set) var visitedPositions: Set<Point> = []
    private(set) var minX = 0
    private(set) var maxX = 0
    private(set) var minY = 0
    private(set) var maxY = 0
    
    private let shouldDump: Bool
    
    init(tails: Int, shouldDump: Bool = false) {
        precondition(tails > 0)
        
        tailPositions = [Point](repeating: .zero, count: tails)
        visitedPositions.insert(tailPositions.last!)
        
        self.shouldDump = shouldDump
    }
    
    func run(instructions: String) {
        for line in inputData.components(separatedBy: "\n") {
            guard let match = line.firstMatch(of: /^(.) (\d+)/) else {
                fatalError("Unmatched line: \(line)")
            }
            
            let (_, direction, stepsString) = match.output
            
            guard let steps = Int(stepsString) else {
                fatalError("Distance wasn't a number: \(stepsString)")
            }
            
            let headDeltaX: Int
            let headDeltaY: Int
            
            switch direction {
            case "U":
                headDeltaX = 0
                headDeltaY = 1
            case "D":
                headDeltaX = 0
                headDeltaY = -1
            case "L":
                headDeltaX = -1
                headDeltaY = 0
            case "R":
                headDeltaX = 1
                headDeltaY = 0
            default:
                fatalError("Unhandled direction: \(direction)")
            }
            
            if shouldDump {
                print()
                print("== \(direction) \(stepsString) == ")
            }
            
            for _ in 0 ..< steps {
                headPosition.x += headDeltaX
                headPosition.y += headDeltaY
                
                minX = min(minX, headPosition.x)
                maxX = max(maxX, headPosition.x)
                minY = min(minY, headPosition.y)
                maxY = max(maxY, headPosition.y)
                
                for (tailIndex, tailPosition) in tailPositions.enumerated() {
                    let previousPosition = tailIndex == 0 ? headPosition : tailPositions[tailIndex - 1]
                    
                    if tailPosition == previousPosition {
                        continue
                    } else if previousPosition.allNeighbors.contains(tailPosition) {
                        continue
                    }
                    
                    let tailDeltaX = previousPosition.x - tailPosition.x
                    let tailDeltaY = previousPosition.y - tailPosition.y
                    
                    if tailDeltaX == 2 && tailDeltaY == 0 {
                        tailPositions[tailIndex].x += 1
                    } else if tailDeltaX == -2 && tailDeltaY == 0 {
                        tailPositions[tailIndex].x -= 1
                    } else if tailDeltaY == 2 && tailDeltaX == 0 {
                        tailPositions[tailIndex].y += 1
                    } else if tailDeltaY == -2 && tailDeltaX == 0 {
                        tailPositions[tailIndex].y -= 1
                    } else {
                        tailPositions[tailIndex].x += tailDeltaX / abs(tailDeltaX)
                        tailPositions[tailIndex].y += tailDeltaY / abs(tailDeltaY)
                    }
                }
                
                visitedPositions.insert(tailPositions.last!)
                
                dumpState()
            }
        }
        
        dumpVisited()
    }
    
    private func dumpState() {
        guard shouldDump else { return }
        
        print()
        
        for y in (minY...maxY).reversed() {
            var line = ""
            
            for x in minX...maxX {
                let point = Point(x: x, y: y)
                
                if point == headPosition {
                    line += "H"
                } else if let index = tailPositions.firstIndex(of: point) {
                    line += "\(index + 1)"
                } else if point == .zero {
                    line += "s"
                } else {
                    line += "."
                }
            }
            
            print(line)
        }
    }
    
    private func dumpVisited() {
        print()
        
        for y in (minY...maxY).reversed() {
            var line = ""
            
            for x in minX...maxX {
                let point = Point(x: x, y: y)
                
                if visitedPositions.contains(point) {
                    line += "#"
                } else {
                    line += "."
                }
            }
            
            print(line)
        }
        
        print("Visited: \(visitedPositions.count)")
    }
}



let inputData = InputData

let bridge1 = Bridge(tails: 1, shouldDump: false)
bridge1.run(instructions: inputData)

let bridge2 = Bridge(tails: 9, shouldDump: false)
bridge2.run(instructions: inputData)
