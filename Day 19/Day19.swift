//
//  main.swift
//  Day 19
//
//  Created by Stephen H. Gerstacker on 2022-12-19.
//  SPDX-License-Identifier: MIT
//

import Foundation
import simd

struct State: Hashable {
    var robots: SIMD4<Int> = .zero // Ore, Clay, Obsidian, Geode
    var materials: SIMD4<Int> = .zero  // Ore, Clay, Obsidian, Geode
}

class Factory {
    
    let blueprintID: Int
    
    private let oreRobotMaterials: SIMD4<Int>
    private let clayRobotMaterials: SIMD4<Int>
    private let obsidianRobotMaterials: SIMD4<Int>
    private let geodeRobotMaterials: SIMD4<Int>
    
    private let maxOreRobots: Int
    private let maxClayRobots: Int
    private let maxObsidianRobots: Int
    
    private let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        let match = data.firstMatch(of: /^Blueprint (\d+): Each ore robot costs (\d+) ore\. Each clay robot costs (\d+) ore\. Each obsidian robot costs (\d+) ore and (\d+) clay\. Each geode robot costs (\d+) ore and (\d+) obsidian\.$/)!
        
        blueprintID = Int(match.output.1)!
        
        oreRobotMaterials = SIMD4<Int>(Int(match.output.2)!, 0, 0, 0)
        clayRobotMaterials = SIMD4<Int>(Int(match.output.3)!, 0, 0, 0)
        obsidianRobotMaterials = SIMD4<Int>(Int(match.output.4)!, Int(match.output.5)!, 0, 0)
        geodeRobotMaterials = SIMD4<Int>(Int(match.output.6)!, 0, Int(match.output.7)!, 0)
        
        maxOreRobots = max(oreRobotMaterials.x, max(clayRobotMaterials.x, max(obsidianRobotMaterials.x, geodeRobotMaterials.x)))
        maxClayRobots = max(oreRobotMaterials.y, max(clayRobotMaterials.y, max(obsidianRobotMaterials.y, geodeRobotMaterials.y)))
        maxObsidianRobots = max(oreRobotMaterials.z, max(clayRobotMaterials.z, max(obsidianRobotMaterials.z, geodeRobotMaterials.z)))

        self.shouldPrint = shouldPrint
    }
    
    func run(totalTime: Int) async -> Int {
        let initialState = State(robots: SIMD4<Int>(1, 0, 0, 0))
        var queue: [State] = [initialState]
        var visited: Set<State> = []
        
        for time in 0 ..< totalTime {
            var nextQueue: [State] = []
            
            if shouldPrint { print("== Minute \(time + 1) ==") }
            
            for state in queue {
                guard !visited.contains(state) else { continue }
                
                visited.insert(state)
                
                if shouldPrint { print("State: \(state.robots) / \(state.materials)") }
                
                if canBuildGeode(state: state) {
                    var nextState = state
                    nextState.robots &+= SIMD4<Int>(0, 0, 0, 1)
                    nextState.materials &-= geodeRobotMaterials
                    
                    if shouldPrint { print("-   Next Build Geode @ \(nextQueue.count): \(nextState.robots) / \(nextState.materials)") }
                    
                    nextState.materials &+= state.robots
                    
                    if shouldPrint { print("-   Generate: + \(state.robots) = \(nextState.materials)") }
                    
                    if !visited.contains(nextState) {
                        nextQueue.append(nextState)
                    }
                } else {
                    if shouldBuildOre(state: state) && canBuildOre(state: state) {
                        var nextState = state
                        nextState.robots &+= SIMD4<Int>(1, 0, 0, 0)
                        nextState.materials &-= oreRobotMaterials
                        
                        if shouldPrint { print("-   Next Build Ore @ \(nextQueue.count): \(nextState.robots) / \(nextState.materials)") }
                        
                        nextState.materials &+= state.robots
                        
                        if shouldPrint { print("-   Generate: + \(state.robots) = \(nextState.materials)") }
                        
                        if !visited.contains(nextState) {
                            nextQueue.append(nextState)
                        }
                    }
                    
                    if shouldBuildClay(state: state) && canBuildClay(state: state) {
                        var nextState = state
                        nextState.robots &+= SIMD4<Int>(0, 1, 0, 0)
                        nextState.materials &-= clayRobotMaterials
                        
                        if shouldPrint { print("-   Next Build Clay @ \(nextQueue.count): \(nextState.robots) / \(nextState.materials)") }
                        
                        nextState.materials &+= state.robots
                        
                        if shouldPrint { print("-   Generate: + \(state.robots) = \(nextState.materials)") }
                        
                        if !visited.contains(nextState) {
                            nextQueue.append(nextState)
                        }
                    }
                    
                    if shouldBuildObsidian(state: state) && canBuildObsidian(state: state) {
                        var nextState = state
                        nextState.robots &+= SIMD4<Int>(0, 0, 1, 0)
                        nextState.materials &-= obsidianRobotMaterials
                        
                        if shouldPrint { print("-   Next Build Obsidian @ \(nextQueue.count): \(nextState.robots) / \(nextState.materials)") }
                        
                        nextState.materials &+= state.robots
                        
                        if shouldPrint { print("-   Generate: + \(state.robots) = \(nextState.materials)") }
                        
                        if !visited.contains(nextState) {
                            nextQueue.append(nextState)
                        }
                    }
                    
                    if !canBuildAll(state: state) {
                        var nextState = state
                        
                        if shouldPrint { print("-   Next Build Nothing @ \(nextQueue.count): \(nextState.robots) / \(nextState.materials)") }
                        
                        nextState.materials &+= state.robots
                        
                        if shouldPrint { print("-   Generate: + \(state.robots) = \(nextState.materials)") }
                        
                        if !visited.contains(nextState) {
                            nextQueue.append(nextState)
                        }
                    }
                }
            }
            
            queue = nextQueue
        }
        
        let maxGeodes = queue.max(by: { $0.materials.w < $1.materials.w })?.materials.w ?? 0
        
        return maxGeodes
    }
    
    private func canBuildAll(state: State) -> Bool {
        canBuildOre(state: state) && canBuildClay(state: state) && canBuildObsidian(state: state)
    }
    
    private func canBuildClay(state: State) -> Bool {
        state.materials.x >= clayRobotMaterials.x
    }
    
    private func canBuildGeode(state: State) -> Bool {
        return state.materials.x >= geodeRobotMaterials.x && state.materials.z >= geodeRobotMaterials.z
    }
    
    private func canBuildObsidian(state: State) -> Bool {
        return state.materials.x >= obsidianRobotMaterials.x && state.materials.y >= obsidianRobotMaterials.y
    }
    
    private func canBuildOre(state: State) -> Bool {
        return state.materials.x >= oreRobotMaterials.x
    }
    
    private func shouldBuildClay(state: State) -> Bool {
        return state.robots.y < maxClayRobots
    }
    
    private func shouldBuildObsidian(state: State) -> Bool {
        return state.robots.z < maxObsidianRobots
    }
    
    private func shouldBuildOre(state: State) -> Bool {
        return state.robots.x < maxOreRobots
    }
}

@main
struct Day19 {
    
    static func main() async {
        print("== Part 1 ==")
        let sampleFactories1 = SampleData.components(separatedBy: "\n").map { Factory(data: $0) }
        let sample1TotalQuality = await run1(factories: sampleFactories1, totalTime: 24)
        print("Sample quality: \(sample1TotalQuality)")
        
        let inputFactories1 = InputData.components(separatedBy: "\n").map { Factory(data: $0) }
        let input1TotalQuality = await run1(factories: inputFactories1, totalTime: 24)
        print("Input quality: \(input1TotalQuality)")
        
        print("== Part 2 ==")
        let sampleFactories2 = SampleData.components(separatedBy: "\n").prefix(3).map { Factory(data: $0) }
        let sample2TotalQuality = await run2(factories: sampleFactories2, totalTime: 32)
        print("Sample quality: \(sample2TotalQuality)")
        
        let inputFactories2 = InputData.components(separatedBy: "\n").prefix(3).map { Factory(data: $0) }
        let input2TotalQuality = await run2(factories: inputFactories2, totalTime: 32)
        print("Input quality: \(input2TotalQuality)")
    }
    
    private static func run1(factories: [Factory], totalTime: Int) async -> Int {
        let result = await withTaskGroup(of: Int.self, returning: Int.self) { taskGroup in
            for factory in factories {
                taskGroup.addTask {
                    let geodes = await factory.run(totalTime: totalTime)
                    let quality = geodes * factory.blueprintID
                    
                    return quality
                }
            }
            
            var totalQuality = 0
            
            for await quality in taskGroup {
                totalQuality += quality
            }
            
            return totalQuality
        }
        
        return result
    }

    private static func run2(factories: [Factory], totalTime: Int) async -> Int {
        let result = await withTaskGroup(of: Int.self, returning: Int.self) { taskGroup in
            for factory in factories {
                taskGroup.addTask {
                    let geodes = await factory.run(totalTime: totalTime)
                    
                    return geodes
                }
            }
            
            var totalQuality = 1
            
            for await quality in taskGroup {
                totalQuality *= quality
            }
            
            return totalQuality
        }
        
        return result
    }
}

