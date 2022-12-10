//
//  DisplayContext.swift
//  Day 10 - Visualized
//
//  Created by Stephen H. Gerstacker on 2022-12-10.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import Visualization
import simd

class DisplayContext: Solution3DContext {
    
    override var name: String {
        "Day 10"
    }
    
    override func run() async throws {
        let computer = Computer()
        
        var display = (0 ..< 6).map { _ in
            (0 ..< 40).map { _ in "." }
        }

        computer.run(inputData: InputData) { _, cycle, registerX in
            let row = (cycle - 1) / 40
            let column = (cycle - 1) % 40
            
            let spritePosition = (registerX - 1) ... (registerX + 1)
            
            if spritePosition.contains(column) {
                display[row][column] = "#"
            }
        }
        
        try loadBoxMesh(name: "Pixel", extents: SIMD3<Float>(1, 1, 1), baseColor: SIMD4<Float>(0, 1, 0, 1))
        
        for y in 0 ..< 6 {
            for x in 0 ..< 40 {
                guard display[y][x] == "#" else { continue }
                addNode(name: "Pixel \(x), \(y)", mesh: "Pixel", batch: "Pixel")
            }
        }
        
        updateCamera(eye: SIMD3<Float>(10, 2, 12), lookAt: SIMD3<Float>(7, 0, 0), up: SIMD3<Float>(0, 1, 0))
        addDirectLight(name: "Sun", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(5, 5, 10), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        
        updatePerspective(near: 0.01, far: 30, angle: .pi / 2)
        
        let animationOffset = 5
        let animationDuration = 30
        let totalFrames = ((40 * 6) * animationOffset) + animationDuration
        let left: Float = (40.0 / -2.0) + 0.5
        let top: Float = (6.0 / 2.0) + 0.5
        
        for frame in (0 ..< totalFrames) {
            for y in 0 ..< 6 {
                for x in 0 ..< 40 {
                    guard display[y][x] == "#" else { continue }
                    
                    let index = (y * 40) + x
                    let rotationStartTime = (index * animationOffset)
                    let rotationEndTime = rotationStartTime + animationDuration
                    
                    let scale: simd_float4x4
                    
                    if frame < rotationStartTime {
                        scale = simd_float4x4(scale: SIMD3<Float>(0, 0, 0))
                    } else if frame >= rotationStartTime && frame <= rotationEndTime {
                        let percent = Float(frame - rotationStartTime) / Float(rotationEndTime - rotationStartTime)
                        let factor = easeOutBack(percent)
                        
                        scale = simd_float4x4(scale: SIMD3<Float>(factor, factor, factor))
                    } else {
                        scale = matrix_identity_float4x4
                    }
                    
                    let rotation = simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: .pi)
                    let translation = simd_float4x4(translate: SIMD3<Float>(left + Float(x), top - Float(y), 0.0))
                    
                    let transform = translation * rotation * scale
                    
                    let nodeName = "Pixel \(x), \(y)"
                    updateNode(name: nodeName, transform: transform)
                }
            }
            
            try snapshot()
        }
    }
}
