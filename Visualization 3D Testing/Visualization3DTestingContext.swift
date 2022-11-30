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
        try runChaos()
        // try runInstances()
        // try runFancyBoxes()
    }
    
    private func runBoxes() throws {
        try loadBoxMesh(name: "Red Box", baseColor: SIMD4<Float>(1.0, 0.0, 0.0, 1.0))
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 5), lookAt: SIMD3<Float>(0, 0, -1), up: SIMD3<Float>(0, 1, 0))
        
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
                updateNode(name: name, transform: transform, metallicFactor: metallic, roughnessFactor: roughness)
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
    
    private func runChaos() throws {
        try loadMesh(name: "Clouds", fromResource: "Clouds")
        try loadMesh(name: "Earth", fromResource: "Earth")
        try loadMesh(name: "Spot", fromResource: "Spot")
        try loadMesh(name: "Stone Block", fromResource: "Stone Block")
        
        try loadTexture(name: "Starscape", resource: "starscape", withExtension: "png")
        
        try loadBoxMesh(name: "Skybox", extents: SIMD3<Float>(100, 100, 100), inwardNormals: true, baseColor: SIMD4<Float>(0, 0, 0, 1), emissiveTexture: "Starscape", roughnessFactor: 1.0)
        try loadSphereMesh(name: "Light", extents: SIMD3<Float>(1, 1, 1), segments: SIMD2<UInt32>(24, 24), baseColor: SIMD4<Float>(1.0, 1.0, 1.0, 1.0), roughnessFactor: 0.5)
        try loadBoxMesh(name: "Cube", extents: SIMD3<Float>(1, 1, 1), baseColor: SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
        try loadPlaneMesh(name: "Plane", extents: SIMD3<Float>(1, 1, 0), baseColor: SIMD4<Float>(0.5, 0.5, 0.5, 1.0))
        
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
        
        updateNode(name: "Cube 1", baseColor: SIMD4<Float>(1, 0, 0, 1), metallicFactor: 0.1, roughnessFactor: 0.1)
        updateNode(name: "Cube 2", baseColor: SIMD4<Float>(0, 1, 0, 1), metallicFactor: 1.0, roughnessFactor: 0.5)
        
        updateNode(name: "Point 1", baseColor: SIMD4<Float>(1, 1, 0, 1))
        updateNode(name: "Point 2", baseColor: SIMD4<Float>(0, 1, 1, 1))
        
        addDirectLight(name: "Sun 1", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(1, 1, 1), up: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1), intensity: 1)
        addDirectLight(name: "Sun 2", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(0, 1, 1), up: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1), intensity: 1)
        addDirectLight(name: "Sun 3", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(-1, 1, 1), up: SIMD3<Float>(0, 1, 0), color: SIMD3<Float>(1, 1, 1), intensity: 1)
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
    
    private func runFancyBoxes() throws {
        try loadMesh(name: "BlueTile", fromResource: "BlueTile")
        try loadMesh(name: "MetalTiles", fromResource: "MetalTiles")
        try loadMesh(name: "Concrete", fromResource: "Concrete")
        try loadMesh(name: "RedPlastic", fromResource: "RedPlastic")
        try loadMesh(name: "RoughMetal", fromResource: "RoughMetal")
        try loadMesh(name: "Wood", fromResource: "Wood")
        
        addNode(name: "Blue Box", mesh: "BlueTile")
        addNode(name: "MetalTiles", mesh: "MetalTiles")
        addNode(name: "Concrete", mesh: "Concrete")
        addNode(name: "RedPlastic", mesh: "RedPlastic")
        addNode(name: "RoughMetal", mesh: "RoughMetal")
        addNode(name: "Wood", mesh: "Wood")
        
        updateNode(name: "Blue Box", transform: simd_float4x4(translate: SIMD3<Float>(-1.2, 0.6, 0.0)))
        updateNode(name: "MetalTiles", transform: simd_float4x4(translate: SIMD3<Float>(0.0, 0.6, 0.0)))
        updateNode(name: "Concrete", transform: simd_float4x4(translate: SIMD3<Float>(1.2, 0.6, 0.0)))
        updateNode(name: "RedPlastic", transform: simd_float4x4(translate: SIMD3<Float>(-1.2, -0.6, 0.0)))
        updateNode(name: "RoughMetal", transform: simd_float4x4(translate: SIMD3<Float>(0.0, -0.6, 0.0)))
        updateNode(name: "Wood", transform: simd_float4x4(translate: SIMD3<Float>(1.2, -0.6, 0.0)))
        
        addPointLight(name: "Light 1", intensity: 25)
        addPointLight(name: "Light 2", intensity: 50)
        addPointLight(name: "Light 3", intensity: 50)
        addPointLight(name: "Light 4", intensity: 150)
        
        updateLight(name: "Light 1", transform: simd_float4x4(lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(-6, 1, 1), up: SIMD3<Float>(0, 1, 0)))
        updateLight(name: "Light 2", transform: simd_float4x4(lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(6, 1, 1), up: SIMD3<Float>(0, 1, 0)))
        updateLight(name: "Light 3", transform: simd_float4x4(lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(0, 1, -6), up: SIMD3<Float>(0, 1, 0)))
        updateLight(name: "Light 4", transform: simd_float4x4(lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(0, 0, 6), up: SIMD3<Float>(0, 1, 0)))
        
        updateCamera(eye: SIMD3<Float>(0.0, 0.2, 3.0), lookAt: normalize(SIMD3<Float>(0.0, 0.0, -1.0)), up: SIMD3<Float>(0, 1, 0))
        
        for frameIndex in 0 ..< 2000 {
            let percentTime = Float(frameIndex) / 2000
            
            let xRadians = (percentTime * .pi) + .pi
            let zRadians = (percentTime * .pi) + .pi
            
            let transform = simd_float4x4(translate: SIMD3<Float>(sin(xRadians) * 2, 0, cos(zRadians)) * 2) *
                simd_float4x4(rotateAbout: SIMD3<Float>(0, 0, 1), byAngle: .pi / 4.0)
            
            updateCamera(eye: transform.columns.3.xyz, lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
            
            try snapshot()
        }
    }
    
    private func runInstances() throws {
        let totalBoxes = 20
        let totalArmadillos = 30
        let totalFruits = 10
        let totalShibas = 5
        
        try loadMesh(name: "Stone Block", fromResource: "Stone Block")
        try loadMesh(name: "Armadillo", fromResource: "Armadillo")
        try loadMesh(name: "Fruit", fromResource: "Fruit")
        try loadMesh(name: "Shiba", fromResource: "Shiba")
        try loadTexture(name: "Starscape", resource: "starscape", withExtension: "png")
        try loadBoxMesh(name: "Skybox", extents: SIMD3<Float>(100, 100, 100), inwardNormals: true, baseColor: SIMD4<Float>(0, 0, 0, 1), emissiveTexture: "Starscape", roughnessFactor: 1.0)
        
        addNode(name: "Skybox", mesh: "Skybox")
        
        let boxNames = (0 ..< totalBoxes).map { "Box \($0)" }
        
        for name in boxNames {
            addNode(name: name, mesh: "Stone Block", batch: "Box")
        }
        
        let armadilloNames = (0 ..< totalArmadillos).map { "Armadillo \($0)" }
        
        for name in armadilloNames {
            addNode(name: name, mesh: "Armadillo", batch: "Armadillo")
        }
        
        let fruitNames = (0 ..< totalFruits).map { "Fruit \($0)" }
        
        for name in fruitNames {
            addNode(name: name, mesh: "Fruit", batch: "Fruit")
        }
        
        let shibaNames = (0 ..< totalShibas).map { "Shiba \($0)" }
        
        for name in shibaNames {
            addNode(name: name, mesh: "Shiba", batch: "Shiba")
        }
        
        updateNode(name: "Skybox", baseColor: SIMD4<Float>(0, 0, 0, 1))
        
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
                position: SIMD3<Float>(Float.random(in: -5...5), Float.random(in: -5...5), Float.random(in: -10 ... -2)),
                rotationAxis: normalize(SIMD3<Float>(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1))),
                rotationAngle: 0,
                angularVelocity: Float.random(in: -0.5...0.5)
            )
        }
        
        var fruitPlacements = (0 ..< totalFruits).map { _ in
            Placement(
                position: SIMD3<Float>(Float.random(in: -5...5), Float.random(in: -5...5), Float.random(in: -10 ... -2)),
                rotationAxis: normalize(SIMD3<Float>(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1))),
                rotationAngle: 0,
                angularVelocity: Float.random(in: -0.5...0.5)
            )
        }
        
        var shibaPlacements = (0 ..< totalShibas).map { _ in
            Placement(
                position: SIMD3<Float>(Float.random(in: -5...5), Float.random(in: -5...5), Float.random(in: -10 ... -2)),
                rotationAxis: normalize(SIMD3<Float>(Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1))),
                rotationAngle: 0,
                angularVelocity: Float.random(in: -0.5...0.5)
            )
        }
        
        addDirectLight(name: "Sun", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(0, 0, 4), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addPointLight(name: "Point 1", color: SIMD3<Float>(0, 0.75, 0.75), intensity: 40.0)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 2), lookAt: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        for frameIndex in 0 ..< 2000 {
            let timeStep = 1.0 / Float(frameRate)
            
            for (index, name) in boxNames.enumerated() {
                boxPlacements[index].rotationAngle += boxPlacements[index].angularVelocity * timeStep * 2
                
                let scale = simd_float4x4(scale: SIMD3<Float>(0.005, 0.005, 0.005))
                let rotation = simd_float4x4(rotateAbout: boxPlacements[index].rotationAxis, byAngle: boxPlacements[index].rotationAngle)
                let translation = simd_float4x4(translate: boxPlacements[index].position)
                
                let transform = translation * rotation * scale
                
                updateNode(name: name, transform: transform)
            }
            
            for (index, name) in armadilloNames.enumerated() {
                armadilloPlacements[index].rotationAngle += armadilloPlacements[index].angularVelocity * timeStep * 2
                
                let scale = simd_float4x4(scale: SIMD3<Float>(0.2, 0.2, 0.2))
                let rotation = simd_float4x4(rotateAbout: armadilloPlacements[index].rotationAxis, byAngle: armadilloPlacements[index].rotationAngle)
                let translation = simd_float4x4(translate: armadilloPlacements[index].position)
                
                let transform = translation * rotation * scale
                
                updateNode(name: name, transform: transform)
            }
            
            for (index, name) in fruitNames.enumerated() {
                fruitPlacements[index].rotationAngle += fruitPlacements[index].angularVelocity * timeStep * 2
                
                let scale = simd_float4x4(scale: SIMD3<Float>(0.05, 0.05, 0.05))
                let rotation = simd_float4x4(rotateAbout: fruitPlacements[index].rotationAxis, byAngle: fruitPlacements[index].rotationAngle)
                let translation = simd_float4x4(translate: fruitPlacements[index].position)
                
                let transform = translation * rotation * scale
                
                updateNode(name: name, transform: transform)
            }
            
            for (index, name) in shibaNames.enumerated() {
                shibaPlacements[index].rotationAngle += shibaPlacements[index].angularVelocity * timeStep * 2
                
                let scale = simd_float4x4(scale: SIMD3<Float>(0.75, 0.75, 0.75))
                let rotation = simd_float4x4(rotateAbout: shibaPlacements[index].rotationAxis, byAngle: shibaPlacements[index].rotationAngle)
                let translation = simd_float4x4(translate: shibaPlacements[index].position)
                
                let transform = translation * rotation * scale
                
                updateNode(name: name, transform: transform)
            }
            
            let percentTime = Float(frameIndex) / 2000
            updateLight(name: "Point 1", transform: simd_float4x4(translate: SIMD3<Float>(0, 0, percentTime * -10.0)))
            
            try snapshot()
        }
    }
    
    private func runMetalSpheres() throws {
        try loadTexture(name: "Rusted Iron Albedo", resource: "rustediron2_basecolor", withExtension: "png")
        try loadTexture(name: "Rusted Iron Metallic", resource: "rustediron2_metallic", withExtension: "png")
        try loadTexture(name: "Rusted Iron Normal", resource: "rustediron2_normal", withExtension: "png")
        try loadTexture(name: "Rusted Iron Roughness", resource: "rustediron2_roughness", withExtension: "png")
        
        try loadSphereMesh(name: "Iron Sphere", baseColorTexture: "Rusted Iron Albedo", metallicTexture: "Rusted Iron Metallic", roughnessTexture: "Rusted Iron Roughness", normalTexture: "Rusted Iron Normal")
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 0.75)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 0.75)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 0.75)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 0.75)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 3), lookAt: SIMD3<Float>(0, 0, -1), up: SIMD3<Float>(0, 1, 0))
        
        let numberOfRows: Float = 3.0
        let numberOfColumns: Float = 3.0
        let spacing: Float = 0.8
        let scale: Float = 0.7
        
        for row in 0 ..< Int(numberOfRows) {
            for column in 0 ..< Int(numberOfColumns) {
                let index = (row * Int(numberOfColumns)) + column
                
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
                    let index = (row * Int(numberOfColumns)) + column
                    
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
        try loadSphereMesh(name: "Red Sphere", baseColor: SIMD4<Float>(1.0, 0.0, 0.0, 1.0))
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 2)
        
        updateCamera(eye: SIMD3<Float>(0, 0, 5), lookAt: SIMD3<Float>(0, 0, -1), up: SIMD3<Float>(0, 1, 0))
        
        let numberOfRows: Float = 7.0
        let numberOfColumns: Float = 7.0
        let spacing: Float = 0.6
        let scale: Float = 0.6
        
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
                
                addNode(name: name, mesh: "Red Sphere")
                updateNode(name: name, transform: transform, metallicFactor: metallic, roughnessFactor: roughness)
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
        try loadMesh(name: "Shiba", fromResource: "Shiba")
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        
        addNode(name: "Shiba", mesh: "Shiba")
        
        updateCamera(eye: SIMD3<Float>(0, 1, 3), lookAt: SIMD3<Float>(0, -1, -3), up: SIMD3<Float>(0, 1, 0))
        
        for index in 0 ..< 2000 {
            let time = Float(index) / Float(frameRate)
            
            let transform = simd_float4x4(rotateAbout: SIMD3<Float>(0, 1, 0), byAngle: time * 0.5) *
                simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: .pi / 2)
            
            updateNode(name: "Shiba", transform: transform)
            
            try snapshot()
        }
    }
    
    private func runStoneBlock() throws {
        try loadMesh(name: "Stone Block", fromResource: "Stone Block")
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        
        addNode(name: "Stone Block", mesh: "Stone Block")
        
        updateCamera(eye: SIMD3<Float>(0, 0, 5), lookAt: SIMD3<Float>(0, 0, -1), up: SIMD3<Float>(0, 1, 0))
        
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
        try loadMesh(name: "Viking Room", fromResource: "Viking Room")
        
        
        addDirectLight(name: "Light 0", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 1", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0,  10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 2", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>(-10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        addDirectLight(name: "Light 3", lookAt: SIMD3<Float>(0, 0, 0.0), from: SIMD3<Float>( 10.0, -10.0, 10.0), up: SIMD3<Float>(0, 1, 0), intensity: 3)
        
        addNode(name: "Viking Room", mesh: "Viking Room")
        
        updateCamera(eye: SIMD3<Float>(0, 1, 8), lookAt: SIMD3<Float>(0, 0, -1), up: SIMD3<Float>(0, 1, 0))
        
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

