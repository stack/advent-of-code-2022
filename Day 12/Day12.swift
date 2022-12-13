//
//  main.swift
//  Day 12
//
//  Created by Stephen H. Gerstacker on 2022-12-12.
//  SPDX-License-Identifier: MIT
//

import Foundation

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

