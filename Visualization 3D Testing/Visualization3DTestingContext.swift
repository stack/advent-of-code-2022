//
//  Visualization3DTestingContext.swift
//  Visualization 3D Testing
//
//  Created by Stephen H. Gerstacker on 2022-11-12.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import QuartzCore
import Visualization
import simd

class Visualization3DTestingContext: Solution3DContext {
    
    override var name: String {
        "Visualization 3D Testing"
    }
    
    override func run() async throws {
        try loadMesh(name: "Clouds", resource: "clouds", withExtension: "obj")
        try loadMesh(name: "Earth", resource: "earth", withExtension: "obj")
        try loadMesh(name: "Spot", resource: "spot_triangulated", withExtension: "obj")
        try loadBoxMesh(name: "Skybox", extents: SIMD3<Float>(100, 100, 100), inwardNormals: true)
        try loadSphereMesh(name: "Moon", extents: SIMD3<Float>(1, 1, 1), segments: SIMD2<UInt32>(24, 24), inwardNormals: false)
        try loadBoxMesh(name: "Cube", extents: SIMD3<Float>(1, 1, 1), inwardNormals: false)
        
        try loadTexture(name: "Starscape", resource: "starscape", withExtension: "png")
        
        try addNode(name: "Spot", mesh: "Spot")
        try addNode(name: "Earth", mesh: "Earth")
        try addNode(name: "Clouds", mesh: "Clouds", parent: "Earth")
        try addNode(name: "Skybox", mesh: "Skybox", texture: "Starscape")
        try addNode(name: "Moon", mesh: "Moon", baseColor: SIMD3<Float>(1, 1, 0), parent: "Earth")
        try addNode(name: "Cube 1", mesh: "Cube", baseColor: SIMD3<Float>(1, 0, 0), diffuseColor: SIMD3<Float>(0.7, 0.7, 0.7), specularColor: SIMD3<Float>(0.1, 0.1, 0.1), specularExponent: 10)
        try addNode(name: "Cube 2", mesh: "Cube", baseColor: SIMD3<Float>(0, 1, 0), diffuseColor: SIMD3<Float>(0.1, 0.1, 0.1), specularColor: SIMD3<Float>(1.0, 1.0, 1.0), specularExponent: 80)
        
        addAmbientLight(name: "Ambient", intensity: 0.7)
        addDirectLight(name: "Sun", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(1, 1, 1), up: SIMD3<Float>(0, 1, 0))
        
        updateCamera(eye: SIMD3<Float>(0, 1, 2), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for index in 0 ..< 1000 {
            let time = (Float(index) * 16.667) / 1000.0
            
            let spotTransform = simd_float4x4(translate: SIMD3<Float>(-5.0 + (Float(index) * 0.01), -1, -3))
            updateNode(name: "Spot", transform: spotTransform)
            
            let earthTransform = simd_float4x4(translate: SIMD3<Float>(sin(time), 0, 0)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -0.5)
            updateNode(name: "Earth", transform: earthTransform)
            
            let cloudTransform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -0.2)
            updateNode(name: "Clouds", transform: cloudTransform)
            
            let moonOrbitalRadius: Float = 2
            let moonRadius: Float = 0.15
            
            let moonTransform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -2.0) *
                simd_float4x4(translate: SIMD3<Float>(moonOrbitalRadius, 0, 0)) *
                simd_float4x4(scale: SIMD3<Float>(repeating: moonRadius))
            updateNode(name: "Moon", transform: moonTransform)
            
            let cube1Transform = simd_float4x4(translate: SIMD3<Float>(-1, 0, 0.5)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: time * -0.8) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -1.0) *
                simd_float4x4(scale: SIMD3<Float>(0.25, 0.25, 0.25))
            updateNode(name: "Cube 1", transform: cube1Transform)
            
            let cube2Transform = simd_float4x4(translate: SIMD3<Float>(-0.5, 0, 0.5)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: time * -0.8) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -1.0) *
                simd_float4x4(scale: SIMD3<Float>(0.25, 0.25, 0.25))
            updateNode(name: "Cube 2", transform: cube2Transform)
            
            try snapshot()
        }
    }
}

