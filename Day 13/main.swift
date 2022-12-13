//
//  main.swift
//  Day 13
//
//  Created by Stephen H. Gerstacker on 2022-12-13.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

indirect enum List: Comparable, CustomStringConvertible {
    case value(Int)
    case list([List])
    
    var description: String {
        switch self {
        case .value(let int):
            return String(int)
        case .list(let values):
            let inner = values.map { $0.description }.joined(separator: ",")
            return "[" + inner + "]"
        }
    }
    
    static func < (lhs: List, rhs: List) -> Bool {
        switch (lhs, rhs) {
        case (.value(let lhsValue), .value(let rhsValue)):
            return lhsValue < rhsValue
        case (.list(let lhsList), .list(let rhsList)):
            let maxCount = min(lhsList.count, rhsList.count)
            
            for index in 0 ..< maxCount {
                if lhsList[index] < rhsList[index] {
                    return true
                } else if lhsList[index] > rhsList[index] {
                    return false
                }
            }
            
            return lhsList.count < rhsList.count
        case (.value(let lhsValue), .list(_)):
            let lhsList = List.list([.value(lhsValue)])
            return lhsList < rhs
        case (.list(_), .value(let rhsValue)):
            let rhsList = List.list([.value(rhsValue)])
            return lhs < rhsList
        }
    }
}

let inputData = InputData

// MARK: - Part 1

var firstList: List? = nil
var secondList: List? = nil
var pairIndex = 1
var correctPairs: [Int] = []

for line in inputData.components(separatedBy: "\n") {
    guard !line.isEmpty else { continue }
    
    let list = parse(data: line)
    
    if firstList == nil {
        firstList = list
    } else if secondList == nil {
        secondList = list
    } else {
        fatalError("No slot to store the parsed list")
    }

    if let first = firstList, let second = secondList {
        print("== Pair \(pairIndex) ==")
        print("- Compare \(first) vs \(second)")
        
        if first < second {
            correctPairs.append(pairIndex)
        }
        
        firstList = nil
        secondList = nil
        
        pairIndex += 1
    }
}

print()
print("Correct pairs: \(correctPairs)")
print("Correct pairs sum: \(correctPairs.reduce(0, +))")

// MARK: - Part 2

let divider1: List = .list([.list([List.value(2)])])
let divider2: List = .list([.list([List.value(6)])])
var allPackets: [List] = [
    divider1, divider2
]

for line in inputData.components(separatedBy: "\n") {
    guard !line.isEmpty else { continue }
    
    let list = parse(data: line)
    allPackets.append(list)
}

let sortedPackets = allPackets.sorted()

print()

for packet in sortedPackets {
    print(packet)
}

let firstIndex = sortedPackets.firstIndex(of: divider1)!
let secondIndex = sortedPackets.firstIndex(of: divider2)!

print()
print("First Index: \(firstIndex + 1)")
print("Second Index: \(secondIndex + 1)")

let decoderKey = (firstIndex + 1) * (secondIndex + 1)

print("Decoder Key: \(decoderKey)")


// MARK: - Utilities

func parse(data: String) -> List {
    var index = data.startIndex
    let result = parse(data: data, index: &index)
    
    guard case .list(let innerResult) = result else {
        fatalError("Parsed data is not correct")
    }
    
    return innerResult[0]
}

func parse(data: String, index: inout String.Index) -> List {
    var result: [List] = []
    
    var buffer = ""
    
    while index < data.endIndex {
        let value = data[index]
        
        if value == "[" {
            index = data.index(after: index)
            result.append(parse(data: data, index: &index))
        } else if value == "]" {
            if !buffer.isEmpty {
                let number = Int(buffer)!
                result.append(.value(number))
                
                buffer.removeAll()
            }
            
            break
        } else if value == "," {
            if !buffer.isEmpty {
                let number = Int(buffer)!
                result.append(.value(number))
                
                buffer.removeAll()
            }
        } else {
            buffer += String(value)
        }
        
        index = data.index(after: index)
    }
    
    return .list(result)
}
