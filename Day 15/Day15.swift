//
//  main.swift
//  Day 15
//
//  Created by Stephen Gerstacker on 2022-12-15.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Algorithms
import Foundation
import Utilities

extension ClosedRange where Bound: Strideable, Bound.Stride: SignedInteger {
    func split(on splitValue: Bound) -> [ClosedRange<Bound>] {
        self.split(separator: splitValue).map {
            let lhs = $0.base[$0.startIndex]
            let rhs = $0.base[$0.index(before: $0.endIndex)]
            
            return lhs ... rhs
        }
    }
}

class Solver {
    
    let sensors: [Point]
    let beacons: [Point]
    
    init(data: String) {
        let regex = /^Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)$/
        
        var sensors: [Point] = []
        var beacons: [Point] = []
        
        for line in data.components(separatedBy: "\n") {
            guard let match = line.firstMatch(of: regex) else {
                fatalError("Data line did not match regex")
            }
            
            let sensor = Point(x: Int(match.output.1)!, y: Int(match.output.2)!)
            let beacon = Point(x: Int(match.output.3)!, y: Int(match.output.4)!)
            
            sensors.append(sensor)
            beacons.append(beacon)
        }
        
        self.sensors = sensors
        self.beacons = beacons
    }
    
    private func run(targetting row: Int) async -> [ClosedRange<Int>] {
        let intersectingBeacons = beacons.filter { $0.y == row }
        var intersections: [ClosedRange<Int>] = []
        
        for (sensor, beacon) in zip(sensors, beacons) {
            let xDistance = abs(sensor.x - beacon.x)
            let yDistance = abs(sensor.y - beacon.y)
            let offset = abs(row - sensor.y)
            let halfWidth = xDistance + (yDistance - offset)
            
            if halfWidth <= 0 {
                continue
            }
            
            let range = (sensor.x - halfWidth) ... (sensor.x + halfWidth)
            
            intersections.append(range)
        }
        
        var combinedIntersections: [ClosedRange<Int>] = []
        
        while !intersections.isEmpty {
            var intersection = intersections.removeFirst()
            
            while let index = intersections.firstIndex(where: { $0.overlaps(intersection) || $0.upperBound == intersection.lowerBound - 1 || $0.lowerBound == intersection.upperBound + 1 }) {
                let otherIntersection = intersections.remove(at: index)
                
                intersection = min(intersection.lowerBound, otherIntersection.lowerBound) ... max(intersection.upperBound, otherIntersection.upperBound)
            }
            
            combinedIntersections.append(intersection)
        }
        
        var splitIntersections = combinedIntersections
        
        for intersectingBeacon in intersectingBeacons {
            if let index = splitIntersections.firstIndex(where: { $0.contains(intersectingBeacon.x) }) {
                let intersection = splitIntersections.remove(at: index)
                let parts = intersection.split(on: intersectingBeacon.x)
                splitIntersections.append(contentsOf: parts)
            }
        }
        
        return splitIntersections.sorted { $0.upperBound < $1.upperBound }
    }
    
    func run1(targetting row: Int) async -> Int {
        let splits = await run(targetting: row)
        let total = splits.reduce(0) { $0 + $1.count }
        return total
    }
    
    func run2(minY: Int, maxY: Int) async -> Int {
        let point = await withTaskGroup(of: [Point].self, returning: Point.self) { taskGroup in
            for ys in (minY ... maxY).chunks(ofCount: (maxY - minY) / ProcessInfo.processInfo.activeProcessorCount) {
                taskGroup.addTask {
                    var points: [Point] = []
                    
                    for y in ys {
                        let splits = await self.run(targetting: y)
                        
                        guard splits.count == 2 else { continue }
                        
                        let possibleX1 = splits[0].upperBound + 1
                        let possibleX2 = splits[1].lowerBound - 1
                        
                        assert(possibleX1 == possibleX2)
                        
                        let possiblePoint = Point(x: possibleX1, y: y)
                        
                        if !self.beacons.contains(possiblePoint) {
                            points.append(possiblePoint)
                        }
                    }
                    
                    return points
                }
            }
            
            var results: [Point] = []
            
            for await points in taskGroup {
                results.append(contentsOf: points)
            }

            assert(results.count == 1)
            
            return results[0]
        }
        
        let result = point.x * 4000000 + point.y
        return result
    }
}

@main
struct Day15 {
    
    static func main() async {
        let clock = ContinuousClock()
        let format: Duration.UnitsFormatStyle = .units(allowed: [.milliseconds], fractionalPart: .show(length: 5))
        
        let sampleSolver = Solver(data: SampleData)
        let inputSolver = Solver(data: InputData)
        
        print("== Part 1 ==")
        let sample1Start = clock.now
        let sampleIntersections = await sampleSolver.run1(targetting: 10)
        let sample1End = clock.now
        print("Sample Intersections: \(sampleIntersections) | \((sample1End - sample1Start).formatted(format))")
        
        let input1Start = clock.now
        let inputIntersections = await inputSolver.run1(targetting: 2000000)
        let input1End = clock.now
        print("Input Intersections: \(inputIntersections) | \((input1End - input1Start).formatted(format))")
        
        print()
        print("== Part 2 ==")
        let sample2Start = clock.now
        let samplePoint = await sampleSolver.run2(minY: 0, maxY: 20)
        let sample2End = clock.now
        print("Sample Point: \(samplePoint) | \((sample2End - sample2Start).formatted(format))")
        
        let input2Start = clock.now
        let inputPoint = await inputSolver.run2(minY: 0, maxY: 4000000)
        let input2End = clock.now
        
        print("Input Point: \(inputPoint) | \((input2End - input2Start).formatted(format))")
    }
}
