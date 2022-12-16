//
//  main.swift
//  Day 16
//
//  Created by Stephen H. Gerstacker on 2022-12-16.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation
import Utilities

class Valve: CustomStringConvertible, CustomDebugStringConvertible {
    let name: String
    let flowRate: Int
    
    var neighbors: [Valve] = []
    var distanceTo: [String:Int] = [:]
    
    init(name: String, flowRate: Int) {
        self.name = name
        self.flowRate = flowRate
    }
    
    var debugDescription: String {
        description
    }
    
    var description: String {
        "\(name) @ \(flowRate) -> \(neighbors.map { $0.name }.joined(separator: ","))"
    }
}

class Volcano {
    
    let valves: [Valve]
    private let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        self.shouldPrint = shouldPrint
        
        var valves: [Valve] = []
        var links: [String:[String]] = [:]
        
        for line in data.components(separatedBy: "\n") {
            guard let match = line.firstMatch(of: /^Valve (.+) has flow rate=(\d+); tunnels? leads? to valves? (.+)$/) else {
                fatalError("Could not match line: \(line)")
            }
            
            let name = String(match.output.1)
            let flowRate = Int(match.output.2)!

            let valve = Valve(name: name, flowRate: flowRate)
            valves.append(valve)
            
            let neighbors = match.output.3.components(separatedBy: ", ").map { String($0) }
            links[name] = neighbors
        }
        
        for (name, neighbors) in links {
            let valve = valves.first(where: { $0.name == name })!
            
            for neighborName in neighbors {
                let neighbor = valves.first(where: { $0.name == neighborName })!
                valve.neighbors.append(neighbor)
            }
        }
        
        self.valves = valves
    }
    
    func findPaths() {
        for sourceValve in valves {
            for targetValve in valves {
                guard sourceValve.name != targetValve.name else { continue }
                sourceValve.distanceTo[targetValve.name] = findPath(from: sourceValve, to: targetValve)
            }
        }
    }
    
    private func findPath(from sourceValve: Valve, to targetValve: Valve) -> Int {
        var frontier = PriorityQueue<Valve>()
        frontier.push(sourceValve, priority: 0)
        
        var cameFrom: [String:String] = [:]
        
        var costSoFar: [String:Int] = [:]
        costSoFar[sourceValve.name] = 0
        
        while !frontier.isEmpty {
            let current = frontier.pop()!
            
            if current.name == targetValve.name {
                break
            }
            
            for neighbor in current.neighbors {
                let newCost = costSoFar[current.name]! + 1
                
                if costSoFar[neighbor.name] == nil || newCost < costSoFar[neighbor.name]! {
                    costSoFar[neighbor.name] = newCost
                    frontier.push(neighbor, priority: newCost)
                    
                    cameFrom[neighbor.name] = current.name
                }
            }
        }
        
        var path: [String] = []
        var current = targetValve.name
        
        while current != sourceValve.name {
            path.append(current)
            current = cameFrom[current]!
        }
        
        if shouldPrint {
            print("\(sourceValve.name) -> \(targetValve.name): \(Array(path.reversed()))")
        }
        
        return path.count
    }
    
    func run1() async {
        let start = valves.first(where: { $0.name == "AA" })!
        let valvesToOpen = valves.filter { $0.flowRate != 0 }
        
        var allPaths: [[Valve]] = []
        explorePath(path: [start], remaining: valvesToOpen, maxTime: 30, goodPaths: &allPaths)
        
        var bestPath: [Valve] = []
        var bestFlow: Int = .min
        
        for path in allPaths {
            let flow = calculatePathFlow(path: path, maxTime: 30)
            
            if flow > bestFlow {
                bestFlow = flow
                bestPath = path
            }
        }
        
        print("Best: \(bestPath.map(\.name)) -> \(bestFlow)")
    }
    
    func run2() async {
        struct Node {
            let path: [Valve]
            let set: Set<String>
            let flow: Int
        }
        
        let start = valves.first(where: { $0.name == "AA" })!
        let valvesToOpen = valves.filter { $0.flowRate != 0 }
        
        var allPaths: [[Valve]] = []
        explorePath(path: [start], remaining: valvesToOpen, maxTime: 26, goodPaths: &allPaths)
        
        let nodes = allPaths.map { path in
            let flow = calculatePathFlow(path: path, maxTime: 26)
            
            var set = Set(path.map(\.name))
            set.remove("AA")
            
            return Node(path: path, set: set, flow: flow)
        }
        
        var bestNodes: [Node] = []
        var bestFlow: Int = .min
        
        for personIndex in 0 ..< nodes.count - 1 {
            let person = nodes[personIndex]
            
            for elephantIndex in (personIndex + 1 ..< nodes.count) {
                let elephant = nodes[elephantIndex]
                
                guard person.set.isDisjoint(with: elephant.set) else { continue }
                
                let flow = person.flow + elephant.flow
                
                if flow > bestFlow {
                    bestNodes = [person, elephant]
                    bestFlow = flow
                }
            }
        }
        
        print("Best: \(bestNodes[0].path.map(\.name)) / \(bestNodes[1].path.map(\.name)) -> \(bestFlow)")
    }
    
    private func calculatePathFlow(path: [Valve], maxTime: Int) -> Int {
        var remainingPath = path
        var current = remainingPath.removeFirst()
        var totalTime = 0
        var flow = 0
        var totalFlow = 0
        
        for other in remainingPath {
            let time = current.distanceTo[other.name]! + 1
            
            totalFlow += flow * time
            totalTime += time
            
            flow += other.flowRate
            
            current = other
        }
        
        if totalTime < maxTime {
            totalFlow += (maxTime - totalTime) * flow
        }
        
        return totalFlow
    }
    
    private func calcultePathTime(path: [Valve]) -> Int {
        var remainingPath = path
        var current = remainingPath.removeFirst()
        var totalTime = 0
        
        for other in remainingPath {
            let time = current.distanceTo[other.name]! + 1
            totalTime += time
            
            current = other
        }
        
        return totalTime
    }
    
    private func explorePath(path: [Valve], remaining: [Valve], maxTime: Int, goodPaths: inout [[Valve]]) {
        let time = calcultePathTime(path: path)
        
        guard time <= maxTime else {
            return
        }
        
        goodPaths.append(path)
        
        for index in 0 ..< remaining.count {
            var nextRemaining = remaining
            nextRemaining.rotate(toStartAt: index)
            
            let nextValue = nextRemaining.removeFirst()
            
            var nextPath = path
            nextPath.append(nextValue)
            
            explorePath(path: nextPath, remaining: nextRemaining, maxTime: maxTime, goodPaths: &goodPaths)
        }
    }
}

@main
struct Day16 {
    
    static func main() async {
        let sampleVolcano = Volcano(data: SampleData)
        sampleVolcano.findPaths()
        
        let inputVolcano = Volcano(data: InputData)
        inputVolcano.findPaths()
        
        print("== Part 1 ==")
        // await sampleVolcano.run1()
        // await inputVolcano.run1()
        
        print("== Part 2 ==")
        await sampleVolcano.run2()
        await inputVolcano.run2()
    }
}
