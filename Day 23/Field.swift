//
//  Field.swift
//  Day 23
//
//  Created by Stephen Gerstacker on 2022-12-23.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation
import Utilities

enum Direction {
    case north
    case south
    case east
    case west
}

class Field {
    
    var initialElves: [Point:UUID] = [:]
    var elves: [Point:UUID] = [:]
    var directions: [Direction] = [.north, .south, .west, .east]
    
    let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        for (y, line) in data.components(separatedBy: "\n").enumerated() {
            for (x, place) in line.enumerated() {
                guard place == "#" else { continue }
                
                let point = Point(x: x, y: y)
                initialElves[point] = UUID()
            }
        }
        
        self.shouldPrint = shouldPrint
    }
    
    @discardableResult
    func run(maxRounds: Int, onStep: (([Point:UUID]) -> Void)? = nil) -> (Int, Int) {
        elves = initialElves
        directions = [.north, .south, .west, .east]
        
        if shouldPrint { printElves(elves) }
        
        var round = 0
        
        while round < maxRounds {
            // Find all of the proposals for movement
            var proposals: [Point:[(UUID, Point)]] = [:]
            var needToMove = 0
            
            for (point, elf) in elves {
                let allNeighborPoints = point.allNeighbors
                let collisions = allNeighborPoints.compactMap { elves[$0] }
                
                guard !collisions.isEmpty else {
                    if shouldPrint { print("\(elf) does not need to move from point \(point)") }
                    
                    var elvesToMove = proposals[point] ?? []
                    elvesToMove.append((elf, point))
                    
                    proposals[point] = elvesToMove
                    
                    continue
                }
                
                needToMove += 1
                
                var didPropose = false
                
                for direction in directions {
                    let neighborPoints = pointsForDirection(point: point, direction: direction)
                    let nextPoint = neighborPoints.first!
                    
                    let collisions = neighborPoints.compactMap { elves[$0] }
                    
                    if collisions.isEmpty {
                        if shouldPrint { print("\(elf) at \(point) proposes moving to \(direction) to \(nextPoint)") }
                        
                        var elvesToMove = proposals[nextPoint] ?? []
                        elvesToMove.append((elf, point))
                        
                        proposals[nextPoint] = elvesToMove
                        didPropose = true
                        
                        break
                    }
                }
                
                if !didPropose {
                    if shouldPrint { print("\(elf) at \(point) cannot move") }
                    
                    var elvesToMove = proposals[point] ?? []
                    elvesToMove.append((elf, point))
                    
                    proposals[point] = elvesToMove
                }
            }
            
            guard needToMove != 0 else {
                break
            }
            
            // Build the next set of elves
            var nextElves: [Point:UUID] = [:]
            
            for (point, elves) in proposals {
                if elves.count == 1 {
                    nextElves[point] = elves.first!.0
                } else {
                    for elf in elves {
                        nextElves[elf.1] = elf.0
                    }
                }
            }
            
            // Advance!
            elves = nextElves
            
            onStep?(elves)
            
            let direction = directions.removeFirst()
            directions.append(direction)
            
            if shouldPrint {
                print()
                printElves(elves)
            }
            
            round += 1
        }
        
        let result = countEmptySpace(elves)
        
        return (result, round + 1)
    }
    
    private func countEmptySpace(_ elves: [Point:UUID]) -> Int {
        let (minX, maxX) = elves.keys.map { $0.x }.minAndMax()!
        let (minY, maxY) = elves.keys.map { $0.y }.minAndMax()!
        
        var emptySpace: Int = 0
        
        for y in minY ... maxY {
            for x in minX ... maxX {
                let point = Point(x: x, y: y)
                
                if elves[point] == nil {
                    emptySpace += 1
                }

            }
        }
        
        return emptySpace
    }
    
    private func pointsForDirection(point: Point, direction: Direction) -> [Point] {
        switch direction {
        case .north:
            return [
                Point(x: point.x, y: point.y - 1),
                Point(x: point.x + 1, y: point.y - 1),
                Point(x: point.x - 1, y: point.y - 1)
            ]
        case .south:
            return [
                Point(x: point.x, y: point.y + 1),
                Point(x: point.x + 1, y: point.y + 1),
                Point(x: point.x - 1, y: point.y + 1)
            ]
        case .west:
            return [
                Point(x: point.x - 1, y: point.y),
                Point(x: point.x - 1, y: point.y - 1),
                Point(x: point.x - 1, y: point.y + 1)
            ]
        case .east:
            return [
                Point(x: point.x + 1, y: point.y),
                Point(x: point.x + 1, y: point.y - 1),
                Point(x: point.x + 1, y: point.y + 1)
            ]
        }
    }
    
    private func printElves(_ elves: [Point:UUID]) {
        let (minX, maxX) = elves.keys.map { $0.x }.minAndMax()!
        let (minY, maxY) = elves.keys.map { $0.y }.minAndMax()!
        
        for y in (minY - 1) ... (maxY + 1) {
            var line = ""
            
            for x in (minX - 1) ... (maxX + 1) {
                let point = Point(x: x, y: y)
                
                if let _ = elves[point] {
                    line += "#"
                } else {
                    line += "."
                }
            }
            
            print(line)
        }
    }
}
