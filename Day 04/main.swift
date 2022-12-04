//
//  main.swift
//  Day 04
//
//  Created by Stephen H. Gerstacker on 2022-12-04.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

let inputData = InputData

let lines = inputData.components(separatedBy: "\n")
let regex = /(\d+)-(\d+),(\d+)-(\d+)/

var totalFullyContains = 0
var totalIntersections = 0

for line in lines {
    let (_, lhsMin, lhsMax, rhsMin, rhsMax) = line.firstMatch(of: regex)!.output
    
    let lhsRange = Int(lhsMin)! ... Int(lhsMax)!
    let rhsRange = Int(rhsMin)! ... Int(rhsMax)!
    
    let lhsSet = Set(lhsRange)
    let rhsSet = Set(rhsRange)
    
    let fullyContains = lhsSet.isSubset(of: rhsSet) || rhsSet.isSubset(of: lhsSet)
    let intersects = lhsSet.intersection(rhsSet).count > 0
    
    print("\(lhsRange) | \(rhsRange) -> \(fullyContains) -> \(intersects)")
    
    if fullyContains {
        totalFullyContains += 1
    }
    
    if intersects {
        totalIntersections += 1
    }
}

print("Fully Contains: \(totalFullyContains)")
print("Intersections: \(totalIntersections)")
