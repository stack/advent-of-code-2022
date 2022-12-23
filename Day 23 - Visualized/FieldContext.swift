//
//  FieldContext.swift
//  Day 23
//
//  Created by Stephen Gerstacker on 2022-12-23.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

import Foundation
import Utilities
import Visualization
import simd

class FieldContext: Solution3DContext {
    
    override var name: String {
        return "Day 23"
    }
    
    override func run() async throws {
        let inputField = Field(data: InputData)
        inputField.run(maxRounds: .max)
        
        let (minX, maxX) = inputField.elves.keys.map { $0.x }.minAndMax()!
        let (minY, maxY) = inputField.elves.keys.map { $0.y }.minAndMax()!
        let width = maxX - minX + 1
        let depth = maxY - minY + 1
        let maxDimension = max(width, depth)
        
        try loadMesh(name: "Elf", fromResource: "Elf")
        try loadTexture(name: "Dirt", resource: "Dirt", withExtension: "jpg")
        try loadPlaneMesh(name: "Floor", extents: SIMD3<Float>(Float(maxDimension + 20), 0, Float(maxDimension + 20)), baseColorTexture: "Dirt")
        
        addNode(name: "Floor", mesh: "Floor")
        
        let left = (Float(maxX - minX + 1) / -2.0) + 0.5
        let back = (Float(maxY - minY + 1) / -2.0) + 0.5
        let elfScale = unitScale(forMesh: "Elf")
        
        for (_, elf) in inputField.elves {
            let nodeName = "Elf \(elf)"
            addNode(name: nodeName, mesh: "Elf", batch: "Elf")
        }
        
        addDirectLight(name: "Sun", lookAt: .zero, from: SIMD3<Float>(10.0, 10.0, 30.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        
        updateCamera(eye: SIMD3<Float>(-20.0, 15, 35), lookAt: SIMD3<Float>(-20.0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        var lastState: [Point:UUID] = [:]
        
        inputField.run(maxRounds: .max) { elves in
            if lastState.isEmpty {
                lastState = elves
            }
            
            var moves: [UUID:(Point, Point)] = [:]
            
            for (point, elf) in elves {
                for (previousPoint, previousElf) in lastState {
                    if elf == previousElf {
                        moves[elf] = (previousPoint, point)
                    }
                }
            }
            
            for offset in stride(from: Float(0.0), through: Float(1.0), by: 0.03) {
                for (elf, (previousPoint, point)) in moves {
                    let nodeName = "Elf \(elf)"
                    
                    let curvedOffset = self.easeInOutQuad(offset)
                    
                    let x = self.lerp(start: Float(previousPoint.x), end: Float(point.x), percent: curvedOffset)
                    let y = self.lerp(start: Float(previousPoint.y), end: Float(point.y), percent: curvedOffset)
                    
                    let translation = simd_float4x4(translate: SIMD3<Float>(left + x, 0, back + y))
                    let rotation = simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: .pi / 2)
                    let scale = elfScale * simd_float4x4(scale: SIMD3<Float>(1.5, 1.5, 1.5))
                    
                    let transform = translation * rotation * scale
                    
                    self.updateNode(name: nodeName, transform: transform)
                }
                
                try! self.snapshot()
            }
            
            lastState = elves
        }
    }
}
