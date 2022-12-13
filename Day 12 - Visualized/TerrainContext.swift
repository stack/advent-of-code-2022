//
//  TerrainContext.swift
//  Day 12 - Visualized
//
//  Created by Stephen H. Gerstacker on 2022-12-12.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Utilities
import Visualization
import simd

class TerrainContext: Solution3DContext {
    
    private let slabHeight: Float = 0.2
    private let boxFactor: Float = 9.0
    private let pointLightHeight: Float = 25.0
    private let pointLightIntensity: Float = 500.0
    private let cameraHeight: Float = 40.0
    
    private var terrain: Terrain!
    private var left: Float = 0.0
    private var back: Float = 0.0
    
    override var name: String {
        "Day 12"
    }
    
    override func run() async throws {
        let inputData = InputData
        terrain = Terrain(data: inputData)
        
        for index in (0 ..< 26) {
            let height = 1.0 + (Float(index) / 25.0) * boxFactor
            try loadBoxMesh(name: "Box \(index)", extents: SIMD3<Float>(1.0, height, 1.0), baseColor: SIMD4<Float>(166.0 / 255.0, 200.0 / 255.0, 171.0 / 255.0, 1.0))
        }
        
        try loadBoxMesh(name: "Green Slab", extents: SIMD3<Float>(1.0, 0.2, 1.0), baseColor: SIMD4<Float>(0.0, 1.0, 0.0, 1.0), metallicFactor: 0.2, roughnessFactor: 0.2)
        try loadBoxMesh(name: "Red Slab", extents: SIMD3<Float>(1.0, 0.2, 1.0), baseColor: SIMD4<Float>(1, 0.0, 0.0, 1.0), metallicFactor: 0.2, roughnessFactor: 0.2)
        try loadBoxMesh(name: "Yellow Slab", extents: SIMD3<Float>(1.0, 0.2, 1.0), baseColor: SIMD4<Float>(1.0, 1.0, 0.0, 1.0))
        
        left = (Float(terrain.width) / -2.0) + 0.5
        back = (Float(terrain.height) / -2.0) + 0.5
        
        for (y, row) in terrain.grid.enumerated() {
            for (x, value) in row.enumerated() {
                let nodeName = terrainName(for: Point(x: x, y: y))
                addNode(name: nodeName, mesh: "Box \(value.0)", batch: "Boxes \(value.0)")
                
                let height = 1.0 + (Float(value.0) / 25.0) * boxFactor
                let translation = simd_float4x4(translate: SIMD3<Float>(left + Float(x), height / 2.0, back + Float(y)))
                
                updateNode(name: nodeName, transform: translation)
            }
        }
        
        let startPoint = terrain.start
        addNode(name: "Start Slab", mesh: "Green Slab")
        
        let startTranslation = slabTranslation(for: startPoint)
        updateNode(name: "Start Slab", transform: startTranslation, baseColor: SIMD4<Float>(0.0, 1.0, 0.0, 1.0))
        
        let endPoint = terrain.end
        addNode(name: "End Slab", mesh: "Red Slab")
        
        let endTranslation = slabTranslation(for: endPoint)
        updateNode(name: "End Slab", transform: endTranslation, baseColor: SIMD4<Float>(1.0, 0.0, 0.0, 1.0))
        
        addPointLight(name: "Point 1", color: SIMD3<Float>(1.0, 1.0, 0.8), intensity: pointLightIntensity)
        updateLight(name: "Point 1", transform: simd_float4x4(translate: SIMD3<Float>(0, pointLightHeight, 0)))
        
        addPointLight(name: "Point 2", color: SIMD3<Float>(1.0, 1.0, 0.8), intensity: pointLightIntensity)
        addPointLight(name: "Point 3", color: SIMD3<Float>(1.0, 1.0, 0.8), intensity: pointLightIntensity)
        
        var previousSlabs: Set<Point> = []
        
        var frameNumber: UInt64 = 0
        
        terrain.run1 { slabs in
            let slabsToAdd = slabs.subtracting(previousSlabs)
            let slabsToRemove = previousSlabs.subtracting(slabs)
            
            for slab in slabsToRemove {
                let name = self.slabName(for: slab)
                self.removeNode(name: name)
            }
            
            for slab in slabsToAdd {
                let slabName = self.slabName(for: slab)
                
                self.addNode(name: slabName, mesh: "Yellow Slab", batch: "Slabs")
            }
            
            for slab in slabs {
                let slabName = self.slabName(for: slab)
                
                let translation = self.slabTranslation(for: slab)
                self.updateNode(name: slabName, transform: translation)
            }
            
            previousSlabs = slabs
            
            self.updateCameraAndLights(frame: frameNumber)
            
            try! self.snapshot()
            
            frameNumber += 1
        }
        
        for _ in 0 ..< 3600 {
            updateCameraAndLights(frame: frameNumber)
            
            try! self.snapshot()
            
            frameNumber += 1
        }
    }

    private func slabName(for point: Point) -> String {
        "Slab (\(point.x), \(point.y))"
    }
    
    private func slabTranslation(for point: Point) -> simd_float4x4 {
        let value = terrain.grid[point.y][point.x]
        
        let baseHeight: Float = 1.0
        let extensionHeight = (Float(value.0) / 25.0) * boxFactor
        
        let y = baseHeight + extensionHeight + (slabHeight / 2)
        
        return simd_float4x4(translate: SIMD3<Float>(left + Float(point.x), y, back + Float(point.y)))
    }
    
    private func terrainName(for point: Point) -> String {
        "Terrain (\(point.x), \(point.y))"
    }
    
    private func updateCameraAndLights(frame: UInt64) {
        let cameraRadius = Float((terrain.width / 2) + 25)
        let sunRadius: Float = 3.0
        let lightRadius = Float(terrain.width / 3)
        
        let angle = (Float(2.0) * .pi) * (Float(frame) / (Float(self.frameRate) * 60.0))
        
        let cameraPosition = SIMD3<Float>(cameraRadius * cos(angle + .pi), self.cameraHeight, cameraRadius * sin(angle + .pi))
        self.updateCamera(eye: cameraPosition, lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        self.removeLight(name: "Sun")
        
        let sunPosition = SIMD3<Float>(sunRadius * cos(angle + (.pi / 2.0)), 20, sunRadius * sin(angle + (.pi / 2.0)))
        let sunLookAt = SIMD3<Float>.zero // SIMD3<Float>(sunRadius * cos(angle + .pi), 0, sunRadius * sin(angle + .pi))
        
        self.addDirectLight(name: "Sun", lookAt: sunLookAt, from: sunPosition, up: SIMD3<Float>(0, 1, 0), intensity: 2)
        
        let light2Position = SIMD3<Float>(lightRadius * cos(angle + .pi), self.pointLightHeight, lightRadius * sin(angle + .pi))
        self.updateLight(name: "Point 2", transform: simd_float4x4(translate: light2Position))
        
        let light3Position = SIMD3<Float>(lightRadius * cos(angle), self.pointLightHeight, lightRadius * sin(angle))
        self.updateLight(name: "Point 3", transform: simd_float4x4(translate: light3Position))
    }
}
