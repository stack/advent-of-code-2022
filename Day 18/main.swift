//
//  main.swift
//  Day 18
//
//  Created by Stephen H. Gerstacker on 2022-12-18.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Utilities

class Solver {
    
    let cubes: Set<Point3D>
    
    let minX: Int
    let maxX: Int
    let minY: Int
    let maxY: Int
    let minZ: Int
    let maxZ: Int
    
    init(data: String) {
        var cubes: Set<Point3D> = []
        
        var minX: Int = .max
        var maxX: Int = .min
        var minY: Int = .max
        var maxY: Int = .min
        var minZ: Int = .max
        var maxZ: Int = .min
        
        for line in data.components(separatedBy: "\n") {
            let match = line.firstMatch(of: /^(\d+),(\d+),(\d+)$/)!
            
            let x = Int(match.output.1)!
            let y = Int(match.output.2)!
            let z = Int(match.output.3)!
            
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
            minZ = min(minZ, z)
            maxZ = max(maxZ, z)
            
            let point = Point3D(x: x, y: y, z: z)
            cubes.insert(point)
        }
        
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
        self.minZ = minZ
        self.maxZ = maxZ
        
        self.cubes = cubes
    }
    
    func run1() -> Int {
        var count = 0
        
        for cube in cubes {
            let neighbors = cube.cardinalNeighbors
            
            for neighbor in neighbors {
                if !cubes.contains(neighbor) {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    func run2() -> Int {
        var waterSet: Set<Point3D> = []
        
        for x in (minX - 1) ... (maxX + 1) {
            for y in (minY - 1) ... (maxY + 1) {
                waterSet.insert(Point3D(x: x, y: y, z: minZ - 1))
                waterSet.insert(Point3D(x: x, y: y, z: maxZ + 1))
            }
        }
        
        for x in (minX - 1) ... (maxX + 1) {
            for z in (minZ - 1) ... (maxZ + 1) {
                waterSet.insert(Point3D(x: x, y: minY - 1, z: z))
                waterSet.insert(Point3D(x: x, y: maxY + 1, z: z))
            }
        }
        
        for y in (minY - 1) ... (maxY + 1) {
            for z in (minZ - 1) ... (maxZ + 1) {
                waterSet.insert(Point3D(x: minX - 1, y: y, z: z))
                waterSet.insert(Point3D(x: maxX + 1, y: y, z: z))
            }
        }
        
        var toVisit: Set<Point3D> = waterSet
        
        while !toVisit.isEmpty {
            let nextCube = toVisit.removeFirst()
            waterSet.insert(nextCube)
            
            let neighbors = nextCube.cardinalNeighbors
            
            for neighbor in neighbors {
                guard neighbor.x >= minX && neighbor.x <= maxX else { continue }
                guard neighbor.y >= minY && neighbor.y <= maxY else { continue }
                guard neighbor.z >= minZ && neighbor.z <= maxZ else { continue }
                
                guard !waterSet.contains(neighbor) else { continue }
                guard !cubes.contains(neighbor) else { continue }
                guard !toVisit.contains(neighbors) else { continue }
                
                toVisit.insert(neighbor)
            }
        }
        
        var count = 0
        
        for cube in cubes {
            let neighbors = cube.cardinalNeighbors
            
            for neighbor in neighbors {
                if waterSet.contains(neighbor) {
                    count += 1
                }
            }
        }
        
        return count
    }
}

let sampleSolver = Solver(data: SampleData)
let inputSolver = Solver(data: InputData)

print("== Part 1 ==")

let sampleCount1 = sampleSolver.run1()
print("Sample Count: \(sampleCount1)")

let inputCount1 = inputSolver.run1()
print("Input Count: \(inputCount1)")

print("== Part 1 ==")

let sampleCount2 = sampleSolver.run2()
print("Sample Count: \(sampleCount2)")

let inputCount2 = inputSolver.run2()
print("Input Count: \(inputCount2)")
