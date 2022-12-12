//
//  main.swift
//  Day 11
//
//  Created by Stephen H. Gerstacker on 2022-12-11.
//  SPDX-License-Identifier: MIT
//

import Foundation

typealias Item = Int64

indirect enum Token {
    case constant(Item)
    case variable
    case add(Token, Token)
    case multiply(Token, Token)
    
    func eval(with variableValue: Item) -> Item {
        switch self {
        case .constant(let value):
            return value
        case .variable:
            return variableValue
        case .add(let lhs, let rhs):
            return lhs.eval(with: variableValue) + rhs.eval(with: variableValue)
        case .multiply(let lhs, let rhs):
            return lhs.eval(with: variableValue) * rhs.eval(with: variableValue)
        }
    }
    
    var fullDescription: String {
        switch self {
        case .constant(let value):
            return String(value)
        case .variable:
            return "old"
        case .add(let lhs, let rhs):
            return lhs.fullDescription + " + " + rhs.fullDescription
        case .multiply(let lhs, let rhs):
            return lhs.fullDescription + " * " + rhs.fullDescription
        }
    }
}

struct Monkey {
    let index: Int
    var items: [Item]
    let operation: Token
    let testDivisor: Item
    let targets: [Int]
    
    var fullDescription: String {
        var lines: [String] = []
        
        lines.append("Monkey \(index)")
        
        let itemsString = items.map { String($0) }.joined(separator: ", ")
        lines.append("  Starting items: \(itemsString)")
        
        lines.append("  Operation: \(operation.fullDescription)")
        lines.append("  Test: divisible by \(testDivisor)")
        lines.append("    If true: throw to monkey \(targets[0])")
        lines.append("    If false: throw to monkey \(targets[1])")
        
        return lines.joined(separator: "\n")
    }
}

let inputData = InputData
let rounds = 10000
let reliefDivisor: Item = 1

let monkeyRegex = /^Monkey (\d+):$/
let startItemsRegex = /Starting items: (.+)$/
let operationRegex = /Operation: new = (.+) ([\+\*]) (.+)$/
let testRegex = /Test: divisible by (\d+)$/
let targetRegex = /If (.+): throw to monkey (\d+)$/

var index: Int = -1
var startingItems: [Item] = []
var operation: Token = .constant(0)
var testDivisor: Item = 0
var targets: [Int] = [-1, -1]

var monkeys: [Monkey] = []
var modulo: Item = 1

for line in inputData.components(separatedBy: "\n") {
    if let match = line.firstMatch(of: monkeyRegex) {
        if index != -1 {
            let monkey = Monkey(index: index, items: startingItems, operation: operation, testDivisor: testDivisor, targets: targets)
            monkeys.append(monkey)
            
            index = -1
            startingItems.removeAll()
            operation = .constant(0)
            testDivisor = 0
            targets = [-1, -1]
        }
        
        index = Int(match.output.1)!
    } else if let match = line.firstMatch(of: startItemsRegex) {
        let itemStrings = match.output.1
        startingItems = itemStrings.components(separatedBy: ", ").map { Item($0)! }
    } else if let match = line.firstMatch(of: operationRegex) {
        let lhs = match.output.1 == "old" ? Token.variable : Token.constant(Item(match.output.1)!)
        let rhs = match.output.3 == "old" ? Token.variable : Token.constant(Item(match.output.3)!)
        
        switch match.output.2 {
        case "+":
            operation = .add(lhs, rhs)
        case "*":
            operation = .multiply(lhs, rhs)
        default:
            fatalError("Invalid operation: \(match.output.2)")
        }
    } else if let match = line.firstMatch(of: testRegex) {
        testDivisor = Item(match.output.1)!
        modulo *= testDivisor
    } else if let match = line.firstMatch(of: targetRegex) {
        switch match.output.1 {
        case "true":
            targets[0] = Int(match.output.2)!
        case "false":
            targets[1] = Int(match.output.2)!
        default:
            fatalError("Invalid target: \(match.output.1)")
        }
    } else if line.isEmpty {
        continue
    } else {
        fatalError("Unhandled line: \(line)")
    }
}

if index != -1 {
    let monkey = Monkey(index: index, items: startingItems, operation: operation, testDivisor: testDivisor, targets: targets)
    monkeys.append(monkey)
}

print("Input Test:")

for monkey in monkeys {
    print()
    print(monkey.fullDescription)
}

// MARK: - Run

var inspections = [Int](repeating: 0, count: monkeys.count)

for round in (0 ..< rounds) {
    // print()
    // print("Round: \(round + 1)")
    
    for monkeyIndex in 0 ..< monkeys.count {
        let monkey = monkeys[monkeyIndex]
        // print("Monkey \(monkey.index)")
        
        while !monkeys[monkeyIndex].items.isEmpty {
            let item = monkeys[monkeyIndex].items.removeFirst()
        
            // print("  Inspects \(item)")
            
            let worryLevel = monkey.operation.eval(with: item)
            // print("    Worry increased to \(worryLevel)")
            
            let reliefLevel = worryLevel / reliefDivisor
            // print("    Worry decreased to \(reliefLevel)")
            
            let finalLevel = reliefLevel % modulo
            
            if finalLevel % monkey.testDivisor == 0 {
                // print("    Worry is divisible by \(monkey.testDivisor). \(finalLevel) goes to \(monkey.targets[0])")
                monkeys[monkey.targets[0]].items.append(finalLevel)
            } else {
                // print("    Worry is not divisible by \(monkey.testDivisor). \(finalLevel) goes to \(monkey.targets[1])")
                monkeys[monkey.targets[1]].items.append(finalLevel)
            }
            
            inspections[monkey.index] += 1
        }
    }
    
    print()
    print("After round \(round + 1), the monkeys are holding:")
    
    for monkey in monkeys {
        print("Monkey \(monkey.index): \(monkey.items.map { String($0) }.joined(separator: ", "))")
    }
    
    print()
    print("After round \(round + 1):")
    
    for (index, inspection) in inspections.enumerated() {
        print("Monkey \(index) inspected items \(inspection) times.")
    }

}

let sortedMonkeys = Array(inspections.sorted().reversed())
let monkeyBusiness = sortedMonkeys[0] * sortedMonkeys[1]

print()
print("Monkey Business: \(monkeyBusiness)")
