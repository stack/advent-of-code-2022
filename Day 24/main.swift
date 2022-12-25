//
//  main.swift
//  Day 24
//
//  Created by Stephen H. Gerstacker on 2022-12-24.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Utilities

class Solver {
    
    typealias Blizzards = [Point:[Direction]]
    
    enum Direction {
        case west
        case north
        case east
        case south
    }
    
    struct State: Hashable {
        let position: Point
        let minute: Int
    }
    
    let startingBlizzard: Blizzards
    var blizzardCache: [Blizzards] = []
    
    let width: Int
    let height: Int
    
    let startingPoint: Point
    let endingPoint: Point
    
    let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        let lines = data.components(separatedBy: "\n")
        
        var blizzards: Blizzards = [:]
        var height = 0
        var width = 0
        
        for (y, line) in lines.enumerated() {
            height += 1
            width = max(width, line.count)
            
            for (x, item) in line.enumerated() {
                let position = Point(x: x, y: y)
                
                switch item {
                case "<":
                    blizzards[position] = [.west]
                case "^":
                    blizzards[position] = [.north]
                case ">":
                    blizzards[position] = [.east]
                case "v":
                    blizzards[position] = [.south]
                default:
                    break
                }
            }
        }
        
        self.startingBlizzard = blizzards
        self.width = width
        self.height = height
        
        let firstLine = lines.first!
        let startIndex = firstLine.firstIndex(of: ".")!
        let startX = firstLine.distance(from: firstLine.startIndex, to: startIndex)
        
        startingPoint = Point(x: startX, y: 0)
            
        let lastLine = lines.last!
        let endIndex = lastLine.firstIndex(of: ".")!
        let endX = lastLine.distance(from: lastLine.startIndex, to: endIndex)
        
        endingPoint = Point(x: endX, y: lines.count - 1)
        
        self.shouldPrint = shouldPrint
        
        blizzardCache.append(startingBlizzard)
        
        while true {
            let nextBlizzards = nextBlizzards(blizzardCache.last!)
            
            if nextBlizzards == blizzardCache.first {
                break
            }
            
            blizzardCache.append(nextBlizzards)
        }
    }
    
    func run1() -> Int {
        let time = travel(start: startingPoint, end: endingPoint, minute: 0)
        return time
    }
    
    func run2() -> (Int, Int, Int) {
        let time1 = travel(start: startingPoint, end: endingPoint, minute: 0)
        let time2 = travel(start: endingPoint, end: startingPoint, minute: time1)
        let time3 = travel(start: startingPoint, end: endingPoint, minute: time2)
        
        return (time1, time2 - time1, time3 - time2)
    }
    
    private func travel(start: Point, end: Point, minute: Int) -> Int {
        let startingState = State(position: start, minute: minute)
        
        var visited: Set<State> = []
        var frontier: [State] = [startingState]

        var lastState: State? = nil
        
        if shouldPrint {
            print("Initial State:")
            printState(startingState)
        }
        
        while !frontier.isEmpty {
            let state = frontier.removeFirst()
            
            if shouldPrint {
                print()
                print("== Current State: ==")
                printState(startingState)
            }
            
            if state.position == end {
                lastState = state
                break
            }
            
            let nextMinute = state.minute + 1
            let nextBlizzards = blizzardCache[nextMinute % blizzardCache.count]
            var nextPositions = state.position.cardinalNeighbors
            nextPositions.append(state.position)
            
            for nextPosition in nextPositions {
                if nextPosition != start && nextPosition != end {
                    guard nextPosition.x > 0 && nextPosition.x < (width - 1) else { continue }
                    guard nextPosition.y > 0 && nextPosition.y < (height - 1) else { continue }
                    guard nextBlizzards[nextPosition] == nil else { continue }
                }
                
                let nextState = State(position: nextPosition, minute: nextMinute)
                
                if shouldPrint {
                    print()
                    print("- Next to \(nextPosition)")
                    printState(nextState)
                }
                
                if !visited.contains(nextState) {
                    frontier.append(nextState)
                    visited.insert(nextState)
                }
            }
        }
        
        return lastState!.minute
    }
    
    private func printState(_ state: State) {
        var startingLine = [String](repeating: "#", count: width)
        startingLine[startingPoint.x] = (startingPoint == state.position) ? "E" : "."
        
        print(startingLine.joined())
        
        let blizzard = blizzardCache[state.minute % blizzardCache.count]
        
        for y in 1 ..< (height - 1) {
            var line = "#"
            
            for x in 1 ..< (width - 1) {
                let point = Point(x: x, y: y)
                
                if let directions = blizzard[point] {
                    if directions.count == 1 {
                        switch directions[0] {
                        case .west: line += "<"
                        case .north: line += "^"
                        case .east: line += ">"
                        case .south: line += "v"
                        }
                    } else {
                        line += String(directions.count)
                    }
                } else {
                    if point == state.position {
                        line += "E"
                    } else {
                        line += "."
                    }
                }
            }
            
            line += "#"
            
            print(line)
        }
        
        var endingLine = [String](repeating: "#", count: width)
        endingLine[endingPoint.x] = (endingPoint == state.position) ? "E" : "."
        
        print(endingLine.joined())
    }
    
    private func nextBlizzards(_ blizzards: Blizzards) -> Blizzards {
        var nextBlizzards: Blizzards = [:]
        
        for (position, directions) in blizzards {
            for direction in directions {
                var nextPosition = position
                
                switch direction {
                case .west:
                    nextPosition.x -= 1
                    if nextPosition.x == 0 { nextPosition.x = width - 2 }
                case .north:
                    nextPosition.y -= 1
                    if nextPosition.y == 0 { nextPosition.y = height - 2 }
                case .east:
                    nextPosition.x += 1
                    if nextPosition.x == (width - 1) { nextPosition.x = 1 }
                case .south:
                    nextPosition.y += 1
                    if nextPosition.y == (height - 1) { nextPosition.y = 1 }
                }
                
                var directions = nextBlizzards[nextPosition] ?? []
                directions.append(direction)
                
                nextBlizzards[nextPosition] = directions
            }
        }
        
        return nextBlizzards
    }
}

let sampleSolver = Solver(data: SampleData)
let inputSolver = Solver(data: InputData)

print("== Part 1 ==")

let sampleMoves1 = sampleSolver.run1()
print("Sample Moves: \(sampleMoves1)")


let inputMoves1 = inputSolver.run1()
print("Input Moves: \(inputMoves1)")

print()
print("== Part 2 ==")

let (sampleMoves2First, sampleMoves2Second, sampleMoves2Third) = sampleSolver.run2()
let sampleMoves2 = sampleMoves2First + sampleMoves2Second + sampleMoves2Third

print("Sample Moves: \(sampleMoves2First) + \(sampleMoves2Second) + \(sampleMoves2Third) = \(sampleMoves2)")

let (inputMoves2First, inputMoves2Second, inputMoves2Third) = inputSolver.run2()
let inputMoves2 = inputMoves2First + inputMoves2Second + inputMoves2Third

print("Sample Moves: \(inputMoves2First) + \(inputMoves2Second) + \(inputMoves2Third) = \(inputMoves2)")
