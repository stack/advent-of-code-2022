//
//  main.swift
//  Day 20
//
//  Created by Stephen H. Gerstacker on 2022-12-20.
//  SPDX-License-Identifier: MIT
//

import Foundation

class Node {
    let value: Int
    
    var previous: Node!
    var next: Node!
    
    init(value: Int) {
        self.value = value
    }
}

class Solver {
    
    private var data: [Int]
    
    private var rootNode: Node
    private let nodeOrder: [Node]
    private let nodeCount: Int
    
    private let shouldPrint: Bool
    
    init(data: String, decryptionKey: Int, shouldPrint: Bool = false) {
        self.data = data.components(separatedBy: "\n").map { Int($0)! }
        
        rootNode = Node(value: self.data[0] * decryptionKey)
        
        var nodeOrder = [rootNode]
        var currentNode = rootNode
        var nodeCount = 1
        
        for (index, value) in self.data.enumerated() {
            guard index != 0 else { continue }
            
            let nextNode = Node(value: value * decryptionKey)
            currentNode.next = nextNode
            nextNode.previous = currentNode
            
            nextNode.next = rootNode
            rootNode.previous = nextNode
            
            nodeOrder.append(nextNode)
            
            currentNode = nextNode
            nodeCount += 1
        }
        
        self.nodeOrder = nodeOrder
        self.nodeCount = nodeCount
        
        self.shouldPrint = shouldPrint
    }
    
    func run(times: Int) -> Int {
        if shouldPrint { print("Initial Arrangment:\n\(nodeState)") }
        
        for _ in 0 ..< times {
            for node in nodeOrder {
                if shouldPrint {
                    print()
                    print("\(node.value) moves:")
                    print("-   \(nodeState)")
                }
                
                guard node.value != 0 else {
                    continue
                }
                
                let previousNode = node.previous!
                let nextNode = node.next!
                
                previousNode.next = nextNode
                nextNode.previous = previousNode
                
                if rootNode === node {
                    rootNode = nextNode
                }
                
                if shouldPrint { print("-   \(nodeState)") }
                
                if node.value > 0 {
                    let nextCount = node.value % (nodeCount - 1)
                    
                    var newPreviousNode = nextNode
                    
                    for _ in 0 ..< (nextCount - 1) {
                        newPreviousNode = newPreviousNode.next
                    }
                    
                    node.previous = newPreviousNode
                    node.next = newPreviousNode.next
                    
                    newPreviousNode.next = node
                    node.next.previous = node
                } else if node.value < 0 {
                    let previousCount = abs(node.value) % (nodeCount - 1)
                    
                    var newNextNode = previousNode
                    
                    for _ in 0 ..< (previousCount - 1) {
                        newNextNode = newNextNode.previous
                    }
                    
                    node.next = newNextNode
                    node.previous = newNextNode.previous
                    
                    newNextNode.previous = node
                    node.previous.next = node
                    
                    if rootNode === newNextNode {
                        rootNode = node
                    }
                }
                
                if shouldPrint { print("-   \(nodeState)") }
            }
        }
        
        var zerothNode = rootNode
        
        while zerothNode.value != 0 {
            zerothNode = zerothNode.next
            assert(zerothNode !== rootNode)
        }
        
        let firstOffset = 1000 % nodeCount
        let secondOffset = 2000 % nodeCount
        let thirdOffset = 3000 % nodeCount
        
        var firstNode = zerothNode
        
        for _ in 0 ..< firstOffset {
            firstNode = firstNode.next
        }
        
        var secondNode = zerothNode
        
        for _ in 0 ..< secondOffset {
            secondNode = secondNode.next
        }
        
        var thirdNode = zerothNode
        
        for _ in 0 ..< thirdOffset {
            thirdNode = thirdNode.next
        }
        
        return firstNode.value + secondNode.value + thirdNode.value
    }
    
    private var nodeState: [Int] {
        var current = rootNode
        var values: [Int] = []
        
        while true {
            values.append(current.value)
            current = current.next
            
            if current === rootNode {
                break
            }
        }
        
        return values
    }
}

print("== Part 1 ==")
let sample1Solver = Solver(data: SampleData, decryptionKey: 1)
let sample1Sum = sample1Solver.run(times: 1)
print("Sample Sum: \(sample1Sum)")

let input1Solver = Solver(data: InputData, decryptionKey: 1)
let input1Sum = input1Solver.run(times: 1)
print("Input Sum: \(input1Sum)")

print()
print("== Part 2 ==")
let sample2Solver = Solver(data: SampleData, decryptionKey: 811589153)
let sample2Sum = sample2Solver.run(times: 10)
print("Sample Sum: \(sample2Sum)")

let input2Solver = Solver(data: InputData, decryptionKey: 811589153)
let input2Sum = input2Solver.run(times: 10)
print("Input Sum: \(input2Sum)")
