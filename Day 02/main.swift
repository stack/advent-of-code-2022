//
//  main.swift
//  Day 02
//
//  Created by Stephen H. Gerstacker on 2022-12-02.
//  SPDX-License-Identifier: MIT
//

import Foundation

enum Play: Int {
    case rock = 1
    case paper = 2
    case scissor = 3
    
    static func fromInput(_ input: String) -> Play {
        switch input {
        case "A": return .rock
        case "B": return .paper
        case "C": return .scissor
        case "X": return .rock
        case "Y": return .paper
        case "Z": return .scissor
        default:
            fatalError("Unknown input: \(input)")
        }
    }
    
    func beats(_ other: Play) -> Bool {
        switch (self, other) {
        case (.rock, .scissor): return true
        case (.scissor, .paper): return true
        case (.paper, .rock): return true
        default:
            return false
        }
    }
    
    func ties(_ other: Play) -> Bool {
        return self == other
    }
    
    var beating: Play {
        switch self {
        case .rock: return .paper
        case .paper: return .scissor
        case .scissor: return .rock
        }
    }
    
    var tying: Play {
        return self
    }
    
    var losing: Play {
        switch self {
        case .rock: return .scissor
        case .paper: return .rock
        case .scissor: return .paper
        }
    }
}

let inputData = InputData

let lines = inputData.split(separator: "\n")

// MARK: - Part 1

var totalScore = 0

for line in lines {
    let parts = line.split(separator: " ").map { String($0) }
    assert(parts.count == 2)
    
    let opponentPlay = Play.fromInput(parts[0])
    let myPlay = Play.fromInput(parts[1])
    
    let playScore = myPlay.rawValue
    
    let outcomeScore: Int
    
    if myPlay.beats(opponentPlay) {
        outcomeScore = 6
    } else if myPlay.ties(opponentPlay) {
        outcomeScore = 3
    } else {
        outcomeScore = 0
    }
    
    let roundScore = playScore + outcomeScore
    totalScore += roundScore
    
    print("\(opponentPlay) vs. \(myPlay) = \(playScore) + \(outcomeScore) = \(roundScore)")
}

print("Total: \(totalScore)")

// MARK: - Part 2

totalScore = 0

for line in lines {
    let parts = line.split(separator: " ").map { String($0) }
    assert(parts.count == 2)
    
    let opponentPlay = Play.fromInput(parts[0])
    
    let myPlay: Play
    
    switch parts[1] {
    case "X":
        myPlay = opponentPlay.losing
    case "Y":
        myPlay = opponentPlay.tying
    case "Z":
        myPlay = opponentPlay.beating
    default:
        fatalError("Invalid play: \(parts[1])")
    }
    
    let playScore = myPlay.rawValue
    
    let outcomeScore: Int
    
    if myPlay.beats(opponentPlay) {
        outcomeScore = 6
    } else if myPlay.ties(opponentPlay) {
        outcomeScore = 3
    } else {
        outcomeScore = 0
    }
    
    let roundScore = playScore + outcomeScore
    totalScore += roundScore
    
    print("\(opponentPlay) vs. \(myPlay) = \(playScore) + \(outcomeScore) = \(roundScore)")
}

print("Total: \(totalScore)")
