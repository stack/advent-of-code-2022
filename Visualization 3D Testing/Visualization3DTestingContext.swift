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
        // try runBoxes()
        // try runSpheres()
        // try runMetalSpheres()
        // try runStoneBlock()
        // try runVikingRoom()
        // try runShiba()
        // try runChaos()
        try runInstances()
    }
    
    private func runBoxes() throws {
        try loadBoxMesh(name: "Red Box", albedo: SIMD3<Float>(1.0, 0.0, 0.0), ambientOcclusion: 1.0)
        
        let lightIntensity = SIMD3<Float>(1, 1, 1)
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 5), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        let numberOfRows: Float = 7.0
        let numberOfColumns: Float = 7.0
        let spacing: Float = 0.6
        let scale: Float = 0.4
        
        for row in 0 ..< Int(numberOfRows) {
            for column in 0 ..< Int(numberOfColumns) {
                let index = (row * 7) + column
                
                let name = "Box \(index)"
                let metallic = Float(row) / numberOfRows
                let roughness = min(max(Float(column) / numberOfColumns, 0.05), 1.0)
                
                let translation = SIMD3<Float>(
                    (spacing * Float(column)) - (spacing * (numberOfColumns - 1.0)) / 2.0,
                    (spacing * Float(row)) - (spacing * (numberOfRows - 1.0)) / 2.0,
                    0.0
                )
                
                let transform = simd_float4x4(translate: translation) * simd_float4x4(scale: SIMD3<Float>(scale, scale, scale))
                
                addNode(name: name, mesh: "Red Box")
                updateNode(name: name, transform: transform, metallic: metallic, roughness: roughness)
                
                print("\(name) -> \(translation)")
                print("-   \(metallic) / \(roughness)")
            }
        }
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            for row in 0 ..< Int(numberOfRows) {
                for column in 0 ..< Int(numberOfColumns) {
                    let index = (row * 7) + column
                    
                    let name = "Box \(index)"
                    
                    let translation = SIMD3<Float>(
                        (spacing * Float(column)) - (spacing * (numberOfColumns - 1.0)) / 2.0,
                        (spacing * Float(row)) - (spacing * (numberOfRows - 1.0)) / 2.0,
                        0.0
                    )
                    
                    let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: sin(time) * 0.8) *
                        simd_float4x4(translate: translation) *
                        simd_float4x4(scale: SIMD3<Float>(scale, scale, scale))
                    
                    updateNode(name: name, transform: transform)
                }
            }
            
            try snapshot()
        }
    }
    
    private func runInstances() throws {
        let totalBoxes = 20
        let totalArmadillos = 30
        
        try loadMesh(name: "Stone Block", fromResource: "Stone Block", withExtension: "usdz")
        try loadMesh(name: "Armadillo", fromResource: "Armadillo", withExtension: "usdz")
        try loadTexture(name: "Starscape", resource: "starscape", withExtension: "png")
        try loadBoxMesh(name: "Skybox", extents: SIMD3<Float>(100, 100, 100), inwardNormals: true, emissive: "Starscape")
        
        addNode(name: "Skybox", mesh: "Skybox")
        addNode(name: "Box", mesh: "Stone Block", instances: totalBoxes)
        addNode(name: "Armadillo", mesh: "Armadillo", instances: totalArmadillos)
        
        struct Placement {
            var position: SIMD3<Float>
            var rotationAxis: SIMD3<Float>
            var rotationAngle: Float
            var angularVelocity: Float
        }
        
        var boxPlacements = (0 ..< totalBoxes).map { _ in
            Placement(
                position: SIMD3<Float>(Float.random(in: -10...10), Float.random(in: -10...10), Float.random(in: -20...0)),
                rotationAxis: normalize(SIMD3<Float>(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1))),
                rotationAngle: 0,
                angularVelocity: Float.random(in: -0.5...0.5)
            )
        }
        
        var armadilloPlacements = (0 ..< totalArmadillos).map { _ in
            Placement(
                position: SIMD3<Float>(Float.random(in: -10...10), Float.random(in: -10...10), Float.random(in: -20...0)),
                rotationAxis: normalize(SIMD3<Float>(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1))),
                rotationAngle: 0,
                angularVelocity: Float.random(in: -0.5...0.5)
            )
        }
        
        addDirectLight(name: "Sun", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(1, 1, 1), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 2), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for frameIndex in 0 ..< 2000 {
            let time = Float(frameIndex) / Float(frameRate)
            
            for index in 0 ..< boxPlacements.count {
                boxPlacements[index].rotationAngle += boxPlacements[index].angularVelocity * time * 0.01
                
                let scale = simd_float4x4(scale: SIMD3<Float>(0.005, 0.005, 0.005))
                let rotation = simd_float4x4(rotateAbout: boxPlacements[index].rotationAxis, byAngle: boxPlacements[index].rotationAngle)
                let translation = simd_float4x4(translate: boxPlacements[index].position)
                
                let transform = translation * rotation * scale
                
                updateNode(name: "Box", instance: index, transform: transform)
            }
            
            for index in 0 ..< armadilloPlacements.count {
                armadilloPlacements[index].rotationAngle += armadilloPlacements[index].angularVelocity * time * 0.01
                
                let scale = simd_float4x4(scale: SIMD3<Float>(0.1, 0.1, 0.1))
                let rotation = simd_float4x4(rotateAbout: armadilloPlacements[index].rotationAxis, byAngle: armadilloPlacements[index].rotationAngle)
                let translation = simd_float4x4(translate: armadilloPlacements[index].position)
                
                let transform = translation * rotation * scale
                
                updateNode(name: "Armadillo", instance: index, transform: transform)
            }
            
            try snapshot()
        }
    }
    
    private func runChaos() throws {
        try loadMesh(name: "Clouds", fromResource: "clouds", withExtension: "obj")
        try loadMesh(name: "Earth", fromResource: "earth", withExtension: "obj")
        try loadMesh(name: "Spot", fromResource: "spot_triangulated", withExtension: "obj")
        try loadMesh(name: "Stone Block", fromResource: "Stone Block", withExtension: "usdz")
        
        try loadTexture(name: "Starscape", resource: "starscape", withExtension: "png")
        
        try loadBoxMesh(name: "Skybox", extents: SIMD3<Float>(100, 100, 100), inwardNormals: true, emissive: "Starscape")
        try loadSphereMesh(name: "Light", extents: SIMD3<Float>(1, 1, 1), segments: SIMD2<UInt32>(24, 24), albedo: SIMD3<Float>(1.0, 1.0, 1.0), roughness: 0.5)
        try loadBoxMesh(name: "Cube", extents: SIMD3<Float>(1, 1, 1), albedo: SIMD3<Float>(1.0, 1.0, 1.0))
        try loadPlaneMesh(name: "Plane", extents: SIMD3<Float>(1, 1, 0), albedo: SIMD3<Float>(0.5, 0.5, 0.5))
        
        addNode(name: "Skybox", mesh: "Skybox")
        addNode(name: "Earth", mesh: "Earth")
        addNode(name: "Clouds", mesh: "Clouds", parent: "Earth")
        addNode(name: "Cube 1", mesh: "Cube")
        addNode(name: "Cube 2", mesh: "Cube")
        addNode(name: "Spot", mesh: "Spot")
        addNode(name: "Moon", mesh: "Stone Block")
        addNode(name: "Plane", mesh: "Plane")
        addNode(name: "Point 1", mesh: "Light")
        addNode(name: "Point 2", mesh: "Light")
        
        updateNode(name: "Cube 1", albedo: SIMD3<Float>(1, 0, 0), metallic: 0.1, roughness: 0.1)
        updateNode(name: "Cube 2", albedo: SIMD3<Float>(0, 1, 0), metallic: 1.0, roughness: 0.5)
        
        updateNode(name: "Point 1", albedo: SIMD3<Float>(1, 1, 0))
        updateNode(name: "Point 2", albedo: SIMD3<Float>(0, 1, 1))
        
        addDirectLight(name: "Sun 1", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(1, 1, 1), up: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1), intensity: 0.75)
        addDirectLight(name: "Sun 2", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(0, 1, 1), up: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1), intensity: 0.75)
        addDirectLight(name: "Sun 3", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(-1, 1, 1), up: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1), intensity: 0.75)
        addPointLight(name: "Point 1", color: SIMD3<Float>(1, 1, 0), intensity: 1.0)
        addPointLight(name: "Point 2", color: SIMD3<Float>(0, 1, 1), intensity: 1.0)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 2), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            let earthTransform = simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: -0.2) * simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -0.5)
                
            updateNode(name: "Earth", transform: earthTransform)
            
            let cloudTransform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -0.2)
            updateNode(name: "Clouds", transform: cloudTransform)
            
            let moonTransform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 0, 1), byAngle: -0.7853982) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -0.5) *
                simd_float4x4(translate: SIMD3<Float>(sin(time * 0.5) * 1, 0, cos(time * 0.5) * 1)) *
                simd_float4x4(scale: SIMD3<Float>(0.001, 0.001, 0.001))
            updateNode(name: "Moon", transform: moonTransform)
            
            let cube1Transform = simd_float4x4(translate: SIMD3<Float>(-0.75, 0, 0)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: time * -0.5) *
                simd_float4x4(scale: SIMD3<Float>(0.25, 0.25, 0.25))
            updateNode(name: "Cube 1", transform: cube1Transform)
            
            let cube2Transform = simd_float4x4(translate: SIMD3<Float>(-1.5, 0, 0)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: time * -0.5) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 0, 1), byAngle: time * -0.5) *
                simd_float4x4(scale: SIMD3<Float>(0.25, 0.25, 0.25))
            updateNode(name: "Cube 2", transform: cube2Transform)
            
            let spotTransform = simd_float4x4(translate: SIMD3<Float>(0.75, -0.25, 0)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * -0.2) *
                simd_float4x4(scale: SIMD3<Float>(0.5, 0.5, 0.5))
            updateNode(name: "Spot", transform: spotTransform)
            
            let planeTransform = simd_float4x4(translate: SIMD3<Float>(1.5, 0, 0)) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: .pi) *
                simd_float4x4(scale: SIMD3<Float>(0.5, 0.5, 0.5))
            updateNode(name: "Plane", transform: planeTransform)
            
            let point1Transform = simd_float4x4(translate: SIMD3<Float>(sin(time) * 1.5, 0.5, 0.5))
            updateLight(name: "Point 1", transform: point1Transform)
            
            let point1NodeTransform = simd_float4x4(translate: SIMD3<Float>(sin(time) * 1.5, 0.5, 0.5)) *
                simd_float4x4(scale: SIMD3<Float>(0.02, 0.02, 0.02))
            updateNode(name: "Point 1", transform: point1NodeTransform)
            
            let point2Transform = simd_float4x4(translate: SIMD3<Float>(cos(time) * -1.5, -0.5, 0.5))
            updateLight(name: "Point 2", transform: point2Transform)
            
            let point2NodeTransform = simd_float4x4(translate: SIMD3<Float>(cos(time) * -1.5, -0.5, 0.5)) *
                simd_float4x4(scale: SIMD3<Float>(0.02, 0.02, 0.02))
            updateNode(name: "Point 2", transform: point2NodeTransform)
            
            try snapshot()
        }
    }
    
    private func runMetalSpheres() throws {
        try loadTexture(name: "Rusted Iron Albedo", resource: "rustediron2_basecolor", withExtension: "png")
        try loadTexture(name: "Rusted Iron Metallic", resource: "rustediron2_metallic", withExtension: "png")
        try loadTexture(name: "Rusted Iron Normal", resource: "rustediron2_normal", withExtension: "png")
        try loadTexture(name: "Rusted Iron Roughness", resource: "rustediron2_roughness", withExtension: "png")
        
        try loadSphereMesh(name: "Iron Sphere", albedo: "Rusted Iron Albedo", metallic: "Rusted Iron Metallic", roughness: "Rusted Iron Roughness", normal: "Rusted Iron Normal")
        
        let lightIntensity = SIMD3<Float>(1, 1, 1)
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 3), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        let numberOfRows: Float = 3.0
        let numberOfColumns: Float = 3.0
        let spacing: Float = 0.8
        let scale: Float = 0.7
        
        for row in 0 ..< Int(numberOfRows) {
            for column in 0 ..< Int(numberOfColumns) {
                let index = (row * 7) + column
                
                let name = "Sphere \(index)"
                
                let translation = SIMD3<Float>(
                    (spacing * Float(column)) - (spacing * (numberOfColumns - 1.0)) / 2.0,
                    (spacing * Float(row)) - (spacing * (numberOfRows - 1.0)) / 2.0,
                    0.0
                )
                
                let transform = simd_float4x4(translate: translation) * simd_float4x4(scale: SIMD3<Float>(scale, scale, scale))
                
                addNode(name: name, mesh: "Iron Sphere")
                updateNode(name: name, transform: transform)
            }
        }
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            for row in 0 ..< Int(numberOfRows) {
                for column in 0 ..< Int(numberOfColumns) {
                    let index = (row * 7) + column
                    
                    let name = "Sphere \(index)"
                    
                    let translation = SIMD3<Float>(
                        (spacing * Float(column)) - (spacing * (numberOfColumns - 1.0)) / 2.0,
                        (spacing * Float(row)) - (spacing * (numberOfRows - 1.0)) / 2.0,
                        0.0
                    )
                    
                    let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: sin(time) * 0.8) *
                        simd_float4x4(translate: translation) *
                        simd_float4x4(scale: SIMD3<Float>(scale, scale, scale))
                    
                    updateNode(name: name, transform: transform)
                }
            }
            
            try snapshot()
        }
    }
    
    private func runSpheres() throws {
        try loadSphereMesh(name: "Red Sphere", albedo: SIMD3<Float>(1.0, 0.0, 0.0), ambientOcclusion: 1.0)
        
        let lightIntensity = SIMD3<Float>(1, 1, 1)
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 5), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        let numberOfRows: Float = 7.0
        let numberOfColumns: Float = 7.0
        let spacing: Float = 0.6
        let scale: Float = 0.4
        
        for row in 0 ..< Int(numberOfRows) {
            for column in 0 ..< Int(numberOfColumns) {
                let index = (row * 7) + column
                
                let name = "Sphere \(index)"
                let metallic = 1.0 - (Float(row) / numberOfRows)
                let roughness = min(max(Float(column) / numberOfColumns, 0.05), 1.0)
                
                let translation = SIMD3<Float>(
                    (spacing * Float(column)) - (spacing * (numberOfColumns - 1.0)) / 2.0,
                    (spacing * Float(row)) - (spacing * (numberOfRows - 1.0)) / 2.0,
                    0.0
                )
                
                let transform = simd_float4x4(translate: translation) * simd_float4x4(scale: SIMD3<Float>(scale, scale, scale))
                
                print("\(name) -> \(translation)")
                print("-   \(metallic) / \(roughness)")
                
                addNode(name: name, mesh: "Red Sphere")
                updateNode(name: name, transform: transform, metallic: metallic, roughness: roughness)
            }
        }
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            for row in 0 ..< Int(numberOfRows) {
                for column in 0 ..< Int(numberOfColumns) {
                    let index = (row * 7) + column
                    
                    let name = "Sphere \(index)"
                    
                    let translation = SIMD3<Float>(
                        (spacing * Float(column)) - (spacing * (numberOfColumns - 1.0)) / 2.0,
                        (spacing * Float(row)) - (spacing * (numberOfRows - 1.0)) / 2.0,
                        0.0
                    )
                    
                    let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: sin(time) * 0.8) *
                        simd_float4x4(translate: translation) *
                        simd_float4x4(scale: SIMD3<Float>(scale, scale, scale))
                    
                    updateNode(name: name, transform: transform)
                }
            }
            
            try snapshot()
        }
    }
    
    private func runShiba() throws {
        try loadMesh(name: "Shiba", fromResource: "Shiba", withExtension: "usdz")
        
        let lightIntensity = SIMD3<Float>(1, 1, 1)
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        
        addNode(name: "Shiba", mesh: "Shiba")
        
        updateCamera(eye: SIMD3<Float>(0, 1, 3), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * 0.5) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: .pi / 2)
            
            updateNode(name: "Shiba", transform: transform)
            
            try snapshot()
        }
    }
    
    private func runStoneBlock() throws {
        try loadMesh(name: "Stone Block", fromResource: "Stone Block", withExtension: "usdz")
        
        let lightIntensity = SIMD3<Float>(1, 1, 1)
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        
        addNode(name: "Stone Block", mesh: "Stone Block")
        
        updateCamera(eye: SIMD3<Float>(0, 0, 5), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * 0.5) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: time * 0.25) *
                simd_float4x4(scale: SIMD3<Float>(0.01, 0.01, 0.01))
            
            updateNode(name: "Stone Block", transform: transform)
            
            try snapshot()
        }
    }
    
    private func runVikingRoom() throws {
        try loadMesh(name: "Viking Room", fromResource: "Viking Room", withExtension: "usdz")
        
        let lightIntensity = SIMD3<Float>(1, 1, 1)
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), color: lightIntensity)
        
        addNode(name: "Viking Room", mesh: "Viking Room")
        
        updateCamera(eye: SIMD3<Float>(0, 1, 8), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * 0.5) *
            simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: -0.5) *
                simd_float4x4(scale: SIMD3<Float>(0.2, 0.2, 0.2))
            
            updateNode(name: "Viking Room", transform: transform)
            
            try snapshot()
        }
    }
}

