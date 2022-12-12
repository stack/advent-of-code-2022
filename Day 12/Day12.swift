//
//  main.swift
//  Day 12
//
//  Created by Stephen H. Gerstacker on 2022-12-12.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Utilities

class Terrain {
    
    let grid: [[(Int,String)]]
    private(set) var start: Point
    let end: Point
    
    let width: Int
    let height: Int
    
    private(set) var frontier = PriorityQueue<Point>()
    private(set) var cameFrom: [Point:Point] = [:]
    private(set) var costSoFar: [Point:Int] = [:]
    
    init(data: String) {
        var grid: [[(Int,String)]] = []
        var start: Point = .zero
        var end: Point = .zero
        
        for (y, line) in data.components(separatedBy: "\n").enumerated() {
            var row: [(Int,String)] = []
            
            for (x, elevation) in line.enumerated() {
                let value: (Int,String)
                
                if elevation == "S" {
                    value = (0, "a")
                    start = Point(x: x, y: y)
                } else if elevation == "E" {
                    value = (25, "z")
                    end = Point(x: x, y: y)
                } else {
                    value = (Int(elevation.asciiValue! - 97), String(elevation))
                }
                
                row.append(value)
            }
            
            grid.append(row)
        }
        
        height = grid.count
        width = grid[0].count
        
        self.grid = grid
        self.start = start
        self.end = end
    }
    
    init(copying other: Terrain) {
        self.grid = other.grid
        self.start = other.start
        self.end = other.end
        
        self.width = other.width
        self.height = other.height
    }
    
    func run1() {
        let path = runInternal(start: start)
        
        print("== Part 1 ==")
        print()
        print("Path: \(path)")
        print("Moves: \(path.count - 1)")
    }
    
    func run2() async {
        var startPoints: [Point] = []
        
        for (y, row) in grid.enumerated() {
            for (x, value) in row.enumerated() {
                if value.1 == "a" {
                    let point = Point(x: x, y: y)
                    startPoints.append(point)
                }
            }
        }
        
        let bestPath = await withTaskGroup(of: [Point].self, returning: [Point].self) { taskGroup in
            for point in startPoints {
                let terrain = Terrain(copying: self)
                
                taskGroup.addTask {
                    return terrain.runInternal(start: point)
                }
            }
            
            var bestPath: [Point] = []
            var bestMoves: Int = .max
            
            for await result in taskGroup {
                guard !result.isEmpty else { continue }
                
                if result.count < bestMoves {
                    bestPath = result
                    bestMoves = result.count
                }
            }
            
            return bestPath
        }
        
        print()
        print("== Part 2 ==")
        print()
        print("Path: \(bestPath)")
        print("Moves: \(bestPath.count - 1)")
    }
    
    private func runInternal(start: Point) -> [Point] {
        frontier.removeAll()
        cameFrom.removeAll()
        costSoFar.removeAll()
        
        frontier.push(start, priority: 0)
        costSoFar[start] = 0
        
        while let current = frontier.pop() {
            if current == end {
                break
            }
            
            let (currentElevation, _) = grid[current.y][current.x]
            
            let neighbors = current.cardinalNeighbors
            
            for neighbor in neighbors {
                guard neighbor.x >= 0 && neighbor.x < width else { continue }
                guard neighbor.y >= 0 && neighbor.y < height else { continue }
                
                let (neighborElevation, _) = grid[neighbor.y][neighbor.x]
                
                guard neighborElevation <= (currentElevation + 1) else { continue }
                
                let newCost = costSoFar[current]! + 1
                
                if costSoFar[neighbor] == nil || newCost < costSoFar[neighbor]! {
                    costSoFar[neighbor] = newCost
                    
                    let priority = newCost + abs(current.x - neighbor.x) + abs(current.y - neighbor.y)
                    frontier.push(neighbor, priority: priority)
                    cameFrom[neighbor] = current
                }
            }
        }
        
        guard cameFrom[end] != nil else {
            return []
        }
        
        var path: [Point] = [end]
        var current = end
        
        while current != start {
            current = cameFrom[current]!
            path.append(current)
        }
        
        return Array(path.reversed())
    }
}

@main
struct Day12 {
    static func main() async {
        let inputData = InputData
        let terrain = Terrain(data: inputData)
        
        let clock = ContinuousClock()
        
        let run1Start = clock.now
        terrain.run1()
        let run1End = clock.now
        
        let run2Start = clock.now
        await terrain.run2()
        let run2End = clock.now
        
        let format: Duration.UnitsFormatStyle = .units(allowed: [.milliseconds], fractionalPart: .show(length: 5))
        
        print()
        print("Part 1: \((run1End - run1Start).formatted(format)))")
        print("Part 1: \((run2End - run2Start).formatted(format)))")
    }
}

