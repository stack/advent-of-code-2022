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
        try loadMesh(name: "Earth", resource: "earth", withExtension: "obj")
        try loadMesh(name: "Spot", resource: "spot_triangulated", withExtension: "obj")
        
        try loadBoxMesh(name: "Box", extents: SIMD3<Float>(1, 1, 1), inwardNormals: false)
        try loadPlaneTexture(name: "Floor", extents: SIMD3<Float>(40, 0, 40))
        try loadSphereMesh(name: "Sphere", extents: SIMD3<Float>(1, 1, 1), segments: SIMD2<UInt32>(20, 20), inwardNormals: false)
        
        try addNode(name: "Box 1", mesh: "Box", color: SIMD3<Float>(1, 0, 0))
        try addNode(name: "Floor", mesh: "Floor", color: SIMD3<Float>(0, 1, 1))
        try addNode(name: "Sphere 1", mesh: "Sphere", color: SIMD3<Float>(1, 1, 0))
        try addNode(name: "Earth", mesh: "Earth")
        try addNode(name: "Spot", mesh: "Spot")
        
        addAmbientLight(name: "Light 1", intensity: 0.1, color: SIMD3<Float>(1, 1, 0))
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(5, 5, 5), up: SIMD3<Float>(0, 1, 0))
        addPointLight(name: "Light 3", intensity: 1.0)
        
        let floorOffset = simd_float4x4(translate: SIMD3<Float>(0, -2, 0))
        updateNode(name: "Floor", transform: floorOffset)
        
        for index in 0 ..< 1000 {
            let boxTransform = simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: Float(index) / 20.0) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: Float(index) / 40.0)
            
            updateNode(name: "Box 1", transform: boxTransform)
            
            let earthTransform = simd_float4x4(translate: SIMD3<Float>(-2, 0, -2)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: Float(index) / 50.0) *
                simd_float4x4(scale: SIMD3<Float>(5.0, 5.0, 5.0))
            updateNode(name: "Earth", transform: earthTransform)
            
            let spotTransform = simd_float4x4(translate: SIMD3<Float>(-2, 0, 0)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: Float(index) / -60.0)
            updateNode(name: "Spot", transform: spotTransform)
            
            let sphereTransform = simd_float4x4(translate: SIMD3<Float>((sin(Float(index) / 40.0) * 2) + 3, 2, 0.1))
            updateNode(name: "Sphere 1", transform: sphereTransform)
            
            let offset = Float(index) / 200.0
            updateCamera(eye: SIMD3<Float>(0, offset, 5), lookAt: .zero, up: SIMD3<Float>(0, 1, 0))
            
            let lightTransform = simd_float4x4(translate: SIMD3<Float>(-2, 2, 0))
            updateLight(name: "Light 3", transform: lightTransform, intensity: 1.0)
            
            try snapshot()
        }
    }
}

