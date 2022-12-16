//
//  main.swift
//  Day 14
//
//  Created by Stephen Gerstacker on 2022-12-14.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation
import Utilities

class Ground {

    var rockSet: Set<Point> = []
    var sandSet: Set<Point> = []
    
    var minX: Int = .max
    var maxX: Int = .min
    var maxY: Int = .min
    
    let source = Point(x: 500, y: 0)
    var currentSand: Point = .zero
    
    let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        self.shouldPrint = shouldPrint
        
        for line in data.components(separatedBy: "\n") {
            let coordinates = line
                .matches(of: /(\d+),(\d+)/)
                .map { Point(x: Int($0.output.1)!, y: Int($0.output.2)!) }
            
            for pairs in coordinates.windows(ofCount: 2) {
                let sortedPairs = pairs.sorted()
                
                let lhs = sortedPairs[0]
                let rhs = sortedPairs[1]
                
                minX = min(minX, min(lhs.x, rhs.x))
                maxX = max(maxX, max(lhs.x, rhs.x))
                maxY = max(maxY, max(lhs.y, rhs.y))
                
                if lhs.x == rhs.x {
                    for y in lhs.y ... rhs.y {
                        rockSet.insert(Point(x: lhs.x, y: y))
                    }
                } else if lhs.y == rhs.y {
                    for x in lhs.x ... rhs.x {
                        rockSet.insert(Point(x: x, y: lhs.y))
                    }
                } else {
                    fatalError("Diagonal line encountered")
                }
            }
        }
    }
    
    func run1() {
        var keepRunning = true
        
        while keepRunning {
            var currentSand = source
            
            if shouldPrint {
                printGround()
            }
            
            while true {
                let down = Point(x: currentSand.x, y: currentSand.y + 1)
                let downLeft = Point(x: currentSand.x - 1, y: currentSand.y + 1)
                let downRight = Point(x: currentSand.x + 1, y: currentSand.y + 1)
                
                if down.y > maxY {
                    keepRunning = false
                    break
                } else if !rockSet.contains(down) && !sandSet.contains(down) {
                    currentSand = down
                } else if !rockSet.contains(downLeft) && !sandSet.contains(downLeft) {
                    currentSand = downLeft
                } else if !rockSet.contains(downRight) && !sandSet.contains(downRight) {
                    currentSand = downRight
                } else {
                    sandSet.insert(currentSand)
                    break
                }
            }
        }
    }
    
    func run2() {
        let floor = maxY + 2
        maxY += 2
        
        var keepRunning = true
        
        while keepRunning {
            var currentSand = source
            
            if shouldPrint {
                printGround()
            }
            
            while true {
                let down = Point(x: currentSand.x, y: currentSand.y + 1)
                let downLeft = Point(x: currentSand.x - 1, y: currentSand.y + 1)
                let downRight = Point(x: currentSand.x + 1, y: currentSand.y + 1)

                if down.y == floor {
                    sandSet.insert(currentSand)
                    break
                } else if !rockSet.contains(down) && !sandSet.contains(down) {
                    currentSand = down
                } else if !rockSet.contains(downLeft) && !sandSet.contains(downLeft) {
                    minX = min(downLeft.x, minX)
                    currentSand = downLeft
                } else if !rockSet.contains(downRight) && !sandSet.contains(downRight) {
                    maxX = max(downRight.x, maxX)
                    currentSand = downRight
                } else if currentSand == source {
                    keepRunning = false
                    break
                } else {
                    sandSet.insert(currentSand)
                    break
                }
            }
        }
    }
    
    func printGround() {
        print()
        
        for y in 0 ... maxY {
            var line = ""
            
            for x in minX ... maxX {
                let point = Point(x: x, y: y)

                if point == source {
                    line += "+"
                } else if point == currentSand {
                    line += "*"
                } else if sandSet.contains(point) {
                    line += "O"
                } else if rockSet.contains(point) {
                    line += "#"
                } else {
                    line += "."
                }
            }
            
            print(line)
        }
    }
}

let inputData = InputData

let ground = Ground(data: inputData)
ground.run2()

print("Sand: \(ground.sandSet.count)")

