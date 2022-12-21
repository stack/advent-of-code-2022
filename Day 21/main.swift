//
//  main.swift
//  Day 21
//
//  Created by Stephen H. Gerstacker on 2022-12-21.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Utilities

enum Operator {
    case add
    case subtract
    case multiply
    case divide
    case equal
    case none
}

class Solver1 {
    var constantMonkeys: [String:Int] = [:]
    var dependentMonkeys: [String:(Operator,String,String)] = [:]
    
    init(data: String) {
        for line in data.components(separatedBy: "\n") {
            if let match = line.firstMatch(of: /^(.+): (.+) ([\+\-\*\/]) (.+)$/) {
                let (_, name, left, opString, right) = match.output
                
                let op: Operator
                
                switch opString {
                case "+": op = .add
                case "-": op = .subtract
                case "*": op = .multiply
                case "/": op = .divide
                default:
                    fatalError("Unhandled operator: \(opString)")
                }
                
                dependentMonkeys[String(name)] = (op, String(left), String(right))
            } else if let match = line.firstMatch(of: /^(.+): (\d+)$/) {
                let (_, name, valueString) = match.output
                let value = Int(valueString)!
                
                constantMonkeys[String(name)] = value
            } else {
                fatalError("Unhandled line: \(line)")
            }
        }
    }
    
    func run() -> Int {
        while !dependentMonkeys.isEmpty {
            let monkeyKeys = dependentMonkeys.keys
            
            for key in monkeyKeys {
                let (op, left, right) = dependentMonkeys[key]!
                
                if let leftMonkey = constantMonkeys[left], let rightMonkey = constantMonkeys[right] {
                    let result: Int
                    
                    switch op {
                    case .add:
                        result = leftMonkey + rightMonkey
                    case .subtract:
                        result = leftMonkey - rightMonkey
                    case .multiply:
                        result = leftMonkey * rightMonkey
                    case .divide:
                        result = leftMonkey / rightMonkey
                    case .equal:
                        fatalError("No monkey can be \"=\" for solution 1")
                    case .none:
                        fatalError("No monkey can be \"none\" for solution 1")
                    }
                    
                    dependentMonkeys.removeValue(forKey: key)
                    constantMonkeys[key] = result
                }
            }
        }

        let rootValue = constantMonkeys["root"]!
        
        return rootValue
    }
}

class Solver2 {
    
    class Monkey {
        let name: String
        let op: Operator
        var value: Int? = nil
        var left: Monkey? = nil
        var right: Monkey? = nil
        
        init(name: String, op: Operator = .none, value: Int? = nil, left: Monkey? = nil, right: Monkey? = nil) {
            self.name = name
            self.op = op
            self.value = value
            self.left = left
            self.right = right
        }
    }
    
    var monkeys: [String:Monkey] = [:]
    let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        var unresolved: [String:(Operator, String, String)] = [:]
        var resolved: [String:Monkey] = [:]
        
        for line in data.components(separatedBy: "\n") {
            if let match = line.firstMatch(of: /^(.+): (.+) ([\+\-\*\/]) (.+)$/) {
                let (_, name, left, opString, right) = match.output
                
                var op: Operator
                
                switch opString {
                case "+": op = .add
                case "-": op = .subtract
                case "*": op = .multiply
                case "/": op = .divide
                default:
                    fatalError("Unhandled operator: \(opString)")
                }
                
                if name == "root" {
                    op = .equal
                }
                
                unresolved[String(name)] = (op, String(left), String(right))
            } else if let match = line.firstMatch(of: /^(.+): (\d+)$/) {
                let (_, name, valueString) = match.output
                
                let value: Int?
                
                if name == "humn" {
                    value = nil
                } else {
                    value = Int(valueString)!
                }
                
                let monkey = Monkey(name: String(name), value: value)
                resolved[String(name)] = monkey
            } else {
                fatalError("Unhandled line: \(line)")
            }
        }
        
        while !unresolved.isEmpty {
            let keys = unresolved.keys
            
            for key in keys {
                let (op, leftName, rightName) = unresolved[key]!
                
                if let leftMonkey = resolved[leftName], let rightMonkey = resolved[rightName] {
                    unresolved.removeValue(forKey: key)
                    
                    let monkey = Monkey(name: key, op: op, left: leftMonkey, right: rightMonkey)
                    resolved[key] = monkey
                }
            }
        }
        
        monkeys = resolved
        
        self.shouldPrint = shouldPrint
    }
    
    func run() -> Int {
        let rootMonkey = monkeys["root"]!
        
        optimize(monkey: rootMonkey)
        
        if shouldPrint { printTree() }
        
        let result = solve()

        return result
    }
    
    private func optimize(monkey: Monkey) {
        guard monkey.name != "humn" else { return }
        
        if let leftMonkey = monkey.left {
            optimize(monkey: leftMonkey)
        }
        
        if let rightMonkey = monkey.right {
            optimize(monkey: rightMonkey)
        }
        
        if monkey.value == nil {
            if let leftMonkey = monkey.left, let leftValue = leftMonkey.value {
                if let rightMonkey = monkey.right, let rightValue = rightMonkey.value {
                    let value: Int?
                    
                    switch monkey.op {
                    case .add: value = leftValue + rightValue
                    case .subtract: value = leftValue - rightValue
                    case .multiply: value = leftValue * rightValue
                    case .divide: value = leftValue / rightValue
                    case .equal: value = nil
                    case .none: value = nil
                    }
                    
                    if let value {
                        monkey.value = value
                    }
                }
            }
        }
    }
    
    private func solve() -> Int {
        let rootMonkey = monkeys["root"]!
        
        guard let leftMonkey = rootMonkey.left else { fatalError("Root does not have a left monkey") }
        guard let rightMonkey = rootMonkey.right else { fatalError("Root does not have a right monkey") }
        
        var completeValue: Int
        var incompleteMonkey: Monkey
        
        if let value = leftMonkey.value {
            completeValue = value
            incompleteMonkey = rightMonkey
        } else if let value = rightMonkey.value {
            completeValue = value
            incompleteMonkey = leftMonkey
        } else {
            fatalError("Root does not have a complete side")
        }
        
        while incompleteMonkey.name != "humn" {
            let leftMonkey = incompleteMonkey.left!
            let rightMonkey = incompleteMonkey.right!
            
            let value: Int
            let nextIncompleteMonkey: Monkey
            let leftSided: Bool
            
            if let v = leftMonkey.value {
                value = v
                nextIncompleteMonkey = rightMonkey
                leftSided = true
            } else if let v = rightMonkey.value {
                value = v
                nextIncompleteMonkey = leftMonkey
                leftSided = false
            } else {
                fatalError("Invalid incomplete monkey: \(incompleteMonkey)")
            }
            
            switch incompleteMonkey.op {
            case .add:
                completeValue -= value
            case .subtract:
                completeValue = leftSided ? value - completeValue : completeValue + value
            case .multiply:
                completeValue /= value
            case .divide:
                completeValue = leftSided ? value / completeValue : completeValue * value
            default:
                fatalError("Unsupported incomplete monkey: \(incompleteMonkey)")
            }
            
            incompleteMonkey = nextIncompleteMonkey
        }

        return completeValue
    }
    
    func printTree() {
        for (_, monkey) in monkeys {
            var result = "\(monkey.name): "
            
            if let value = monkey.value {
                result += "(\(value)) "
            } else {
                result += "(???) "
            }
            
            if let leftMonkey = monkey.left, let rightMonkey = monkey.right {
                let opString: String
                
                switch monkey.op {
                case .add: opString = "+"
                case .subtract: opString = "-"
                case .multiply: opString = "*"
                case .divide: opString = "/"
                case .equal: opString = "="
                case .none: opString = " "
                }
                
                result += "\(leftMonkey.name) \(opString) \(rightMonkey.name)"
            }
            
            print(result)
        }
    }
}

print("== Part 1 ==")

let (sampleSolver1, sample1ParseDuration) = benchmark { Solver1(data: SampleData) }
let (sample1Root, sample1RunDuration) = benchmark { sampleSolver1.run() }

print()
print("Sample Root: \(sample1Root)")
print("-   Parse: \(sample1ParseDuration.formatted(.benchmark))")
print("-     Run: \(sample1RunDuration.formatted(.benchmark))")
print("-   Total: \((sample1ParseDuration + sample1RunDuration).formatted(.benchmark))")

let (inputSolver1, input1ParseDuration) = benchmark { Solver1(data: InputData) }
let (input1Root, input1RunDuration) = benchmark { inputSolver1.run() }

print()
print("Input Root: \(input1Root)")
print("-   Parse: \(input1ParseDuration.formatted(.benchmark))")
print("-     Run: \(input1RunDuration.formatted(.benchmark))")
print("-   Total: \((input1ParseDuration + input1RunDuration).formatted(.benchmark))")

print()
print("== Part 2 ==")
print()

let (sampleSolver2, sample2ParseDuration) = benchmark { Solver2(data: SampleData) }
let (sample2Value, sample2RunDuration) = benchmark { sampleSolver2.run() }

print("Sample Value: \(sample2Value)")
print("-   Parse: \(sample2ParseDuration.formatted(.benchmark))")
print("-     Run: \(sample2RunDuration.formatted(.benchmark))")
print("-   Total: \((sample2ParseDuration + sample2RunDuration).formatted(.benchmark))")

let (inputSolver2, input2ParseDuration) = benchmark { return Solver2(data: InputData) }
let (input2Value, input2RunDuration) = benchmark { inputSolver2.run() }

print()
print("Input Value: \(input2Value)")
print("-   Parse: \(input2ParseDuration.formatted(.benchmark))")
print("-     Run: \(input2RunDuration.formatted(.benchmark))")
print("-   Total: \((input2ParseDuration + input2RunDuration).formatted(.benchmark))")
