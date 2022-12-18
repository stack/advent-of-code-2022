//
//  main.swift
//  Day 17
//
//  Created by Stephen H. Gerstacker on 2022-12-17.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import Utilities

enum Direction {
    case left
    case right
}

enum Tetromino {
    case minus
    case plus
    case angle
    case line
    case box
    
    var next: Tetromino {
        switch self {
        case .minus: return .plus
        case .plus:  return .angle
        case .angle: return .line
        case .line:  return .box
        case .box:   return .minus
        }
    }
    
    func points(from origin: Int) -> [Point] {
        switch self {
        case .minus:
            return [
                Point(x: 2, y: origin + 3),
                Point(x: 3, y: origin + 3),
                Point(x: 4, y: origin + 3),
                Point(x: 5, y: origin + 3),
            ]
        case .plus:
            return [
                Point(x: 3, y: origin + 5),
                Point(x: 2, y: origin + 4),
                Point(x: 3, y: origin + 4),
                Point(x: 4, y: origin + 4),
                Point(x: 3, y: origin + 3),
            ]
        case .angle:
            return [
                Point(x: 4, y: origin + 5),
                Point(x: 4, y: origin + 4),
                Point(x: 2, y: origin + 3),
                Point(x: 3, y: origin + 3),
                Point(x: 4, y: origin + 3),
            ]
        case .line:
            return [
                Point(x: 2, y: origin + 6),
                Point(x: 2, y: origin + 5),
                Point(x: 2, y: origin + 4),
                Point(x: 2, y: origin + 3),
            ]
        case .box:
            return [
                Point(x: 2, y: origin + 4),
                Point(x: 3, y: origin + 4),
                Point(x: 2, y: origin + 3),
                Point(x: 3, y: origin + 3),
            ]
        }
    }
}

class Cave {
    
    let directions: [Direction]
    private(set) var directionIndex: Int = 0
    
    private(set) var tetromino: Tetromino = .minus
    private(set) var tetrominoPoints: [Point] = []
    
    let width: Int
    private(set) var usedSpace: [[Int]] = []
    private(set) var usedSpaceSet: Set<Point> = []
    private(set) var highestPoint: Int = 0
    private(set) var patternRange: ClosedRange<Int>? = nil
    
    let shouldPrint: Bool
    
    init(data: String, width: Int, shouldPrint: Bool = false) {
        directions = data.map { $0 == "<" ? .left : .right }
        
        self.width = width
        self.shouldPrint = shouldPrint
    }
    
    private func isUsed(_ point: Point) -> Bool {
        return usedSpaceSet.contains(point)
    }
    
    private func drop() -> Bool {
        if shouldPrint {
            printState()
        }
        
        let nextPoints = tetrominoPoints.map { Point(x: $0.x, y: $0.y - 1) }
        
        var didInsert = false
        
        for point in nextPoints {
            if isUsed(point) || point.y == -1 {
                for newPoint in tetrominoPoints {
                    if patternRange == nil {
                        while usedSpace.count <= newPoint.y {
                            usedSpace.append([])
                        }
                        
                        usedSpace[newPoint.y].append(newPoint.x)
                    }
                    
                    usedSpaceSet.insert(newPoint)
                    
                    highestPoint = max(highestPoint, newPoint.y)
                }
                
                didInsert = true
                
                if let patternRange {
                    let lowestPoint = (highestPoint - patternRange.count - 50)
                    
                    usedSpaceSet = usedSpaceSet.filter { $0.y >= lowestPoint }
                }
                
                break
            }
        }
        
        if didInsert {
            if shouldPrint {
                print("!!! Done !!!")
            }
            
            tetrominoPoints = []
            
            return true
        } else {
            tetrominoPoints = nextPoints
            
            if shouldPrint {
                print("ooo Next ooo")
                printState()
            }
            
            return false
        }
    }
    
    private func shift() {
        let movement = directions[directionIndex]
        directionIndex = (directionIndex + 1) % directions.count
        
        if shouldPrint {
            switch movement {
            case .left: print("<< Left <<")
            case .right: print(">> Right >>")
            }
        }
        
        var movedPoints = tetrominoPoints
        let xOffset = movement == .left ? -1 : 1
        
        for index in 0 ..< movedPoints.count {
            movedPoints[index].x += xOffset
        }
        
        var shouldMove = true
        
        for point in movedPoints {
            if point.x == -1 {
                shouldMove = false
            } else if point.x >= width {
                shouldMove = false
            } else if isUsed(point) {
                shouldMove = false
            }
            
            if !shouldMove {
                break
            }
        }
        
        if shouldMove {
            tetrominoPoints = movedPoints
        }
    }
    
    func run(totalRocks: Int) {
        directionIndex = 0
        
        tetromino = .minus
        tetrominoPoints = []
        
        usedSpace.removeAll()
        usedSpaceSet.removeAll()
        
        highestPoint = -1
        patternRange = nil
        
        for rock in 0 ..< totalRocks {
            tetrominoPoints = tetromino.points(from: highestPoint + 1)
            tetromino = tetromino.next
            
            if shouldPrint {
                print("== Start ==")
                printState()
            }
            
            while true {
                shift()
                
                let didInsert = drop()
                
                if didInsert {
                    break
                }
            }
            
            if patternRange == nil,  let pattern = findPattern() {
                print("!!! Found pattern: \(pattern)")
                
                patternRange = pattern
            }
        }
        
        printState()
    }
    
    private func findPattern() -> ClosedRange<Int>? {
        guard highestPoint > 10 else { return nil }
        
        for rangeHeight in (3 ..< (highestPoint / 2)).reversed() {
            let maxY = highestPoint - (rangeHeight * 2)
            
            for y in 0 ... maxY {
                let lhsRange = y ... (y + rangeHeight - 1)
                let rhsRange = (y + rangeHeight) ... (y + rangeHeight + rangeHeight - 1)
                
                let lhs = usedSpace[lhsRange]
                let rhs = usedSpace[rhsRange]
                
                if lhs == rhs {
                    return lhsRange
                }
            }
        }
        
        return nil
    }
    
    private func printState(onlyUsed: Bool = false) {
        print()
        
        let highestY = tetrominoPoints.map { $0.y }.max() ?? usedSpace.count
        
        for y in (0 ... highestY).reversed() {
            var line = "\(String(format: "%5i", y)) |"
            
            for x in 0 ..< width {
                let point = Point(x: x, y: y)
                
                if !onlyUsed && tetrominoPoints.contains(point) {
                    line += "@"
                } else if isUsed(point) {
                    line += "#"
                } else {
                    line += "."
                }
            }
            
            line += "|"
            
            print(line)
        }
        
        print("      +\(String(repeating: "-", count: width))+")
    }
}

let sampleCave = Cave(data: SampleData, width: 7, shouldPrint: false)
let inputCave = Cave(data: InputData, width: 7)

print("== Part 1 ==")

sampleCave.run(totalRocks: 2022)
print("Sample Highest Point: \(sampleCave.highestPoint + 1)")

inputCave.run(totalRocks: 2022)
print("Input Highest Point: \(inputCave.highestPoint + 1)")

print("== Part 2 ==")

sampleCave.run(totalRocks: 1000000000000)
print("Sample Highest Point: \(sampleCave.highestPoint + 1)")

inputCave.run(totalRocks: 1000000000000)
print("Input Highest Point: \(inputCave.highestPoint + 1)")

