//
//  ShipyardContext.swift
//  Day 05 - Visualized
//
//  Created by Stephen Gerstacker on 2022-12-05.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import QuartzCore
import Visualization
import simd

class ShipyardContext: Solution3DContext {
    
    private let craneMode: Shipyard.CraneMode = .model9000
    private let inputData: String = InputData
    
    private var crateUnitScale: simd_float4x4 = matrix_identity_float4x4
    private var maxStacks: Int = 0
    private var maxHeight: Int = .min
    private var left: Float = 0.0
    private var bottom: Float = 0.0
    
    override var name: String {
        "Day 05"
    }
    
    override func run() async throws {
        // Load the initial assets needed to build the nodes
        try loadMesh(name: "Crate", fromResource: "Wooden_Crate")
        crateUnitScale = unitScale(forMesh: "Crate")
        
        // Run the simulation one time to get the maximum height and load all the nodes
        let testShipyard = Shipyard(mode: craneMode, shouldDump: false)
        
        for line in inputData.components(separatedBy: "\n") {
            let previousMode = testShipyard.parserMode
            testShipyard.parseLine(line)
            
            if testShipyard.parserMode == .moves && previousMode == .crates {
                for stack in testShipyard.stacks {
                    for crate in stack {
                        addNode(name: "Crate \(crate.id)", mesh: "Crate", batch: "Crate")
                    }
                }
                
                maxStacks = testShipyard.stacks.count
            }
            
            if testShipyard.parserMode == .moves {
                let currentMaxHeight = testShipyard.stacks.map { $0.count }.max() ?? 0
                maxHeight = max(currentMaxHeight, maxHeight)
            }
        }
    
        // Complete the scene
        left = (Float(maxStacks) / -2.0) + 0.5
        bottom = (Float(maxHeight) / -2.0) + 0.5
        
        addDirectLight(name: "Sun", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(1, -1, 1), up: SIMD3<Float>(0, 1, 0), intensity: 1)
        
        addPointLight(name: "Point 1", intensity: 200)
        updateLight(name: "Point 1", transform: simd_float4x4(translate: SIMD3<Float>(0, bottom, 10)))
        
        addPointLight(name: "Point 2", intensity: 200)
        updateLight(name: "Point 2", transform: simd_float4x4(translate: SIMD3<Float>(0, -bottom, 10)))
        
        addPointLight(name: "Point 3", intensity: 200)
        updateLight(name: "Point 3", transform: simd_float4x4(translate: SIMD3<Float>(0, 0, 10)))
        
        updateCamera(eye: SIMD3<Float>(0, 0, 20), lookAt: SIMD3<Float>(0, bottom, -30), up: SIMD3<Float>(0, 1, 0))
        
        // Run the simulation again, this time rendering the results
        let shipyard = Shipyard(mode: .model9000, shouldDump: false)
        
        for line in inputData.components(separatedBy: "\n") {
            shipyard.parseLine(line)
            
            if shipyard.parserMode == .moves {
                let currentMaxHeight = shipyard.stacks.map { $0.count }.max() ?? 0
                
                if !shipyard.lastMoves.isEmpty {
                    // Set the stage for the non-moving crates
                    update(shipyard: shipyard)
                    
                    // Set the stage for the moving crates to their original spots
                    for lastMove in shipyard.lastMoves {
                        for (crateIndex, crate) in lastMove.crates.enumerated() {
                            let scale = crateUnitScale
                            let rotation = matrix_identity_float4x4
                            let translation = simd_float4x4(translate: SIMD3<Float>(left + Float(lastMove.sourceColumn), bottom + Float(lastMove.sourceRow + crateIndex), 0.0))
                            
                            let transform = translation * rotation * scale
                            
                            let name = "Crate \(crate.id)"
                            updateNode(name: name, transform: transform)
                        }
                    }
                    
                    for lastMove in shipyard.lastMoves {
                        try animate(crates: lastMove.crates, startX: lastMove.sourceColumn, startY: lastMove.sourceRow, endX: lastMove.sourceColumn, endY: currentMaxHeight)
                        try animate(crates: lastMove.crates, startX: lastMove.sourceColumn, startY: currentMaxHeight, endX: lastMove.targetColumn, endY: currentMaxHeight)
                        try animate(crates: lastMove.crates, startX: lastMove.targetColumn, startY: currentMaxHeight, endX: lastMove.targetColumn, endY: lastMove.targetRow)
                    }
                } else {
                    update(shipyard: shipyard)
                    
                    for _ in 0 ..< 60 {
                        try snapshot()
                    }
                }
            }
        }
    }
    
    private func animate(crates: [Shipyard.Crate], startX: Int, startY: Int, endX: Int, endY: Int) throws {
        let xDistance = endX - startX
        let yDistance = endY - startY
        let distance = sqrt(Float(xDistance * xDistance) + Float(yDistance * yDistance))
        
        let timePerUnit: Float = 0.1
        let totalTime = timePerUnit * distance
        let totalFrames = Int(round(totalTime * Float(frameRate)))
        
        for frame in (0 ..< totalFrames) {
            let progress = Float(frame) / Float(totalFrames)
            let curvedProgress = easeInOutQuad(progress)
            
            let xOffset = lerp(start: Float(startX), end: Float(endX), percent: curvedProgress)
            
            for (crateIndex, crate) in crates.enumerated() {
                let yOffset = lerp(start: Float(startY + crateIndex), end: Float(endY + crateIndex), percent: curvedProgress)
                
                let scale = crateUnitScale
                let rotation = matrix_identity_float4x4
                let translation = simd_float4x4(translate: SIMD3<Float>(left + xOffset, bottom + yOffset, 0.0))
                
                let transform = translation * rotation * scale
                
                let crateName = "Crate \(crate.id)"
                updateNode(name: crateName, transform: transform)
            }
            
            try snapshot()
        }
    }
    
    private func update(shipyard: Shipyard) {
        for (stackIndex, stack) in shipyard.stacks.enumerated() {
            for (crateIndex, crate) in stack.enumerated() {
                let scale = crateUnitScale
                let rotation = matrix_identity_float4x4
                let translation = simd_float4x4(translate: SIMD3<Float>(left + Float(stackIndex), bottom + Float(crateIndex), 0.0))

                let transform = translation * rotation * scale
                
                let name = "Crate \(crate.id)"
                updateNode(name: name, transform: transform)
            }
        }
    }
}
