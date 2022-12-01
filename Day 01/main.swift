//
//  main.swift
//  Day 01
//
//  Created by Stephen Gerstacker on 2022-12-01.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Algorithms
import Foundation

protocol Solution {
    func run(input: String)
}

class NaiveSolution: Solution {

    struct Elf: CustomStringConvertible {
        var index: Int
        var calories: [Int] = []
        
        var totalCalories: Int {
            calories.reduce(0, +)
        }
        
        var description: String {
            "Elf \(index): \(totalCalories)"
        }
    }
    
    var currentElf = Elf(index: 1)
    var allElves: [Elf] = []

    let clock = ContinuousClock()
    
    func run(input: String) {
        // MARK: - Injest
        let injestStart = clock.now

        let lines = input.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            guard !line.isEmpty  else {
                allElves.append(currentElf)
                currentElf = Elf(index: currentElf.index + 1)
                
                continue
            }
            
            guard let amount = Int(line) else {
                fatalError("Calorie line \"\(line)\" could not be parsed")
            }
                           
            currentElf.calories.append(amount)
        }

        if !currentElf.calories.isEmpty {
            allElves.append(currentElf)
        }

        let injestEnd = clock.now

        // MARK: - Part 1
        let part1Start = clock.now

        let maxElf = allElves.max { $0.totalCalories < $1.totalCalories }!

        let part1End = clock.now

        print ("Max Elf: \(maxElf)")

        // MARK: - Part 2
        let part2Start = clock.now

        let sortedElves = allElves.sorted { $0.totalCalories > $1.totalCalories }
        let top3Elves = sortedElves[0 ..< 3]
        let top3Total = top3Elves.reduce(0) { $0 + $1.totalCalories }

        let part2End = clock.now

        print("Top 3 Elves: \(top3Elves)")
        print("Top 3 Total: \(top3Total)")

        // MARK: - Stats
        let injestTime = injestEnd - injestStart
        let part1Time = part1End - part1Start
        let part2Time = part2End - part2Start
        let totalTime = injestTime + part1Time + part2Time

        let format: Duration.UnitsFormatStyle = .units(allowed: [.milliseconds], fractionalPart: .show(length: 5))
        print("Injest: \(injestTime.formatted(format))")
        print("Part 1: \(part1Time.formatted(format))")
        print("Part 2: \(part2Time.formatted(format))")
        print("Total:  \(totalTime.formatted(format))")
    }
}

class FastSolution: Solution {
    
    var elves: [Int] = []
    
    let clock = ContinuousClock()
    
    func run(input: String) {
        // MARK: - Injest
        var currentIndex = 0
        elves.append(0)
        
        let injestStart = clock.now

        let lines = input.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            guard !line.isEmpty else {
                elves.append(0)
                currentIndex += 1
                
                continue
            }
            
            guard let amount = Int(line) else {
                fatalError("Calorie line \"\(line)\" could not be parsed")
            }
            
            elves[currentIndex] += amount
        }
        
        let injestEnd = clock.now
        
        // MARK: - Part 1
        
        let part1Start = clock.now
        
        let max = elves.max()!
        
        let part1End = clock.now
        
        print("Max: \(max)")
        
        // MARK: - Part 2
        
        let part2Start = clock.now
        
        let topCalories = elves.max(count: 3)
        let topMax = topCalories.reduce(0, +)
        
        let part2End = clock.now
        
        print("Top Max: \(topMax)")
        
        // MARK: - Stats
        let injestTime = injestEnd - injestStart
        let part1Time = part1End - part1Start
        let part2Time = part2End - part2Start
        let totalTime = injestTime + part1Time + part2Time

        let format: Duration.UnitsFormatStyle = .units(allowed: [.milliseconds], fractionalPart: .show(length: 5))
        print("Injest: \(injestTime.formatted(format))")
        print("Part 1: \(part1Time.formatted(format))")
        print("Part 2: \(part2Time.formatted(format))")
        print("Total:  \(totalTime.formatted(format))")
    }
}

let inputData = InputData

print("Naïve solution:")
let naiveSolution = NaiveSolution()
naiveSolution.run(input: inputData)

print()

print("Fast solution:")
let fastSolution = FastSolution()
fastSolution.run(input: inputData)
